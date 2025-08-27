# Task Specification: Company Management System with Role-Based Access Control

## Overview

Implement a comprehensive Company Management System with role-based permissions that allows users to create and manage companies, control member access, and maintain organizational structure through a secure, scalable micro-frontend architecture.

## Core Requirements

### 1. Company Creation & Management
- Create companies with essential details (name, description, address, phone, email, website)
- Automatic admin assignment for company creators
- Field validation and duplicate company name prevention
- Company status management (ACTIVE/DELETED)
- Clean, organized company information display

### 2. Role-Based Access Control (RBAC)
- **Admin Role**: Full company management, member management, role assignment
- **Member Role**: Read-only access to company information
- **Owner Role**: Super-admin with transfer and deletion capabilities
- Clear UI indicators for role-based actions and permissions

### 3. Member Management
- Add/remove company members
- Role assignment and modification (Admin only)
- Member invitation system with email notifications
- Member list display with roles and status
- User search and invitation capabilities

## Technical Architecture

### Database Schema Changes (DynamoDB Single-Table)

#### Core Entities
```typescript
// Enhanced Company Entity
Company {
  PK: "COMPANY#{companyId}",
  SK: "COMPANY#{companyId}",
  id: string,
  name: string,
  description?: string,
  address: string,
  phone: string,
  email?: string,
  website?: string,
  status: 'ACTIVE' | 'DELETED',
  ownerId: string,
  createdAt: string,
  updatedAt: string,
  memberCount: number,
  settings: CompanySettings
}

// Company-User Associations (with roles)
CompanyMember {
  PK: "COMPANY#{companyId}",
  SK: "USER#{userId}",
  userId: string,
  companyId: string,
  role: 'OWNER' | 'ADMIN' | 'MEMBER',
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED',
  invitedBy: string,
  invitedAt: string,
  joinedAt?: string,
  permissions: string[]
}

// User-Company Memberships (reverse lookup)
UserCompanyMembership {
  PK: "USER#{userId}",
  SK: "COMPANY#{companyId}",
  companyId: string,
  userId: string,
  role: 'OWNER' | 'ADMIN' | 'MEMBER',
  status: 'ACTIVE' | 'PENDING' | 'SUSPENDED',
  companyName: string, // denormalized for quick display
  joinedAt: string
}

// Invitation Management
CompanyInvitation {
  PK: "INVITATION#{invitationId}",
  SK: "INVITATION#{invitationId}",
  id: string,
  companyId: string,
  email: string,
  role: 'ADMIN' | 'MEMBER',
  invitedBy: string,
  invitedAt: string,
  expiresAt: string,
  status: 'PENDING' | 'ACCEPTED' | 'EXPIRED' | 'CANCELLED',
  token: string // for secure invitation links
}

// Audit Trail
CompanyAuditLog {
  PK: "COMPANY#{companyId}",
  SK: "AUDIT#{timestamp}#{actionId}",
  companyId: string,
  userId: string,
  action: string,
  targetUserId?: string,
  oldValue?: any,
  newValue?: any,
  timestamp: string,
  ipAddress?: string,
  userAgent?: string
}
```

#### Global Secondary Indexes (GSI)
```typescript
// GSI1: User-Company Reverse Lookup
GSI1PK: "USER#{userId}",
GSI1SK: "COMPANY#{companyId}"

// GSI2: Email-based lookups for invitations
GSI2PK: "EMAIL#{email}",
GSI2SK: "INVITATION#{invitationId}"

// GSI3: Company status and member count queries
GSI3PK: "STATUS#{status}",
GSI3SK: "COMPANY#{companyId}"
```

### Backend API Endpoints

#### Company Management (`/api/companies/v1/`)
```typescript
// Existing endpoints (enhanced)
GET    /companies                    // List companies (with member filtering)
GET    /companies/{id}               // Get company details (role-aware)
POST   /companies                    // Create company
PUT    /companies/{id}               // Update company (admin only)
DELETE /companies/{id}               // Delete company (owner only)

// New RBAC endpoints
GET    /companies/{id}/members       // List company members
POST   /companies/{id}/members       // Add member/send invitation
PUT    /companies/{id}/members/{userId} // Update member role
DELETE /companies/{id}/members/{userId} // Remove member
POST   /companies/{id}/invitations   // Send invitation
GET    /companies/{id}/invitations   // List pending invitations
DELETE /companies/{id}/invitations/{invitationId} // Cancel invitation

// Member self-service
GET    /companies/my-memberships     // List user's company memberships
POST   /invitations/{token}/accept   // Accept invitation
POST   /invitations/{token}/decline  // Decline invitation
POST   /companies/{id}/leave         // Leave company

// Admin operations
GET    /companies/{id}/audit-logs    // Get audit trail (admin only)
POST   /companies/{id}/bulk-invite   // Bulk member invitation
PUT    /companies/{id}/transfer-ownership // Transfer ownership
```

#### Permission Validation Middleware
```typescript
interface Permission {
  action: string;
  resource: string;
  conditions?: Record<string, any>;
}

const permissions = {
  OWNER: [
    { action: '*', resource: 'company' },
    { action: '*', resource: 'member' },
    { action: 'transfer', resource: 'ownership' }
  ],
  ADMIN: [
    { action: 'read|update', resource: 'company' },
    { action: '*', resource: 'member' },
    { action: 'read', resource: 'audit' }
  ],
  MEMBER: [
    { action: 'read', resource: 'company' },
    { action: 'read', resource: 'member', conditions: { self: true } }
  ]
};
```

### Frontend Implementation

#### Enhanced Redux State Management
```typescript
// Company slice with RBAC
interface CompanyState {
  companies: Company[];
  selectedCompany: Company | null;
  members: CompanyMember[];
  invitations: CompanyInvitation[];
  currentUserRole: UserRole | null;
  permissions: Permission[];
  loading: {
    companies: boolean;
    members: boolean;
    invitations: boolean;
  };
  errors: {
    companies: string | null;
    members: string | null;
    invitations: string | null;
  };
}
```

#### Key Components

**1. Enhanced Business Management Dashboard**
```typescript
// src/app/page.tsx
export default function BusinessManagementPage() {
  return (
    <div className="space-y-6">
      <CompanyRoleProvider>
        <Tabs defaultValue="companies">
          <TabsList>
            <TabsTrigger value="companies">Companies</TabsTrigger>
            <TabsTrigger value="members">Members</TabsTrigger>
            <TabsTrigger value="invitations">Invitations</TabsTrigger>
            <TabsTrigger value="financial">Financial</TabsTrigger>
          </TabsList>
          
          <TabsContent value="companies">
            <CompanyManagementPanel />
          </TabsContent>
          
          <TabsContent value="members">
            <RoleGuard requiredRoles={['OWNER', 'ADMIN']}>
              <MemberManagementPanel />
            </RoleGuard>
          </TabsContent>
          
          <TabsContent value="invitations">
            <RoleGuard requiredRoles={['OWNER', 'ADMIN']}>
              <InvitationManagementPanel />
            </RoleGuard>
          </TabsContent>
          
          <TabsContent value="financial">
            <FinancialDashboard />
          </TabsContent>
        </Tabs>
      </CompanyRoleProvider>
    </div>
  );
}
```

**2. Role-Based UI Components**
```typescript
// src/components/rbac/RoleGuard.tsx
interface RoleGuardProps {
  requiredRoles: UserRole[];
  requiredPermissions?: string[];
  fallback?: React.ReactNode;
  children: React.ReactNode;
}

// src/components/rbac/PermissionButton.tsx
interface PermissionButtonProps extends ButtonProps {
  requiredPermission: string;
  resource?: string;
  fallback?: React.ReactNode;
}

// src/components/company/MemberManagementPanel.tsx
export function MemberManagementPanel() {
  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h2>Team Members</h2>
        <PermissionButton 
          requiredPermission="member:invite"
          onClick={() => setInviteModalOpen(true)}
        >
          Invite Members
        </PermissionButton>
      </div>
      
      <MemberList members={members} />
      <InviteMemberModal />
      <BulkInviteModal />
    </div>
  );
}
```

**3. Member Management Components**
```typescript
// src/components/members/MemberList.tsx
export function MemberList({ members }: { members: CompanyMember[] }) {
  return (
    <div className="space-y-4">
      {members.map(member => (
        <MemberCard key={member.userId} member={member} />
      ))}
    </div>
  );
}

// src/components/members/MemberCard.tsx
export function MemberCard({ member }: { member: CompanyMember }) {
  const { canUpdateRole, canRemoveMember } = usePermissions();
  
  return (
    <Card>
      <CardContent>
        <div className="flex justify-between items-center">
          <MemberInfo member={member} />
          <div className="flex gap-2">
            {canUpdateRole && (
              <RoleSelector 
                currentRole={member.role}
                onRoleChange={(role) => updateMemberRole(member.userId, role)}
              />
            )}
            {canRemoveMember && (
              <RemoveMemberButton memberId={member.userId} />
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
```

**4. Invitation System**
```typescript
// src/components/invitations/InviteMemberModal.tsx
export function InviteMemberModal() {
  const { register, handleSubmit } = useForm<InvitationForm>();
  
  const onSubmit = (data: InvitationForm) => {
    inviteMember({
      email: data.email,
      role: data.role,
      message: data.message
    });
  };
  
  return (
    <Dialog>
      <DialogContent>
        <form onSubmit={handleSubmit(onSubmit)}>
          <Input {...register('email')} placeholder="Email address" />
          <Select {...register('role')}>
            <SelectItem value="MEMBER">Member</SelectItem>
            <SelectItem value="ADMIN">Admin</SelectItem>
          </Select>
          <Textarea {...register('message')} placeholder="Personal message" />
          <Button type="submit">Send Invitation</Button>
        </form>
      </DialogContent>
    </Dialog>
  );
}
```

### Security Implementation

#### JWT Token Enhancement
```typescript
interface JWTPayload {
  userId: string;
  email: string;
  companies: Array<{
    companyId: string;
    role: UserRole;
    permissions: string[];
  }>;
  iat: number;
  exp: number;
}
```

#### Permission Middleware
```typescript
export const requirePermission = (permission: string, resource?: string) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    const user = req.user;
    const companyId = req.params.companyId;
    
    const hasPermission = await checkUserPermission(
      user.userId,
      companyId,
      permission,
      resource
    );
    
    if (!hasPermission) {
      return res.status(403).json({
        error: 'Insufficient permissions',
        required: permission,
        resource
      });
    }
    
    next();
  };
};
```

### Testing Strategy

#### Backend Unit Tests
```typescript
describe('Company RBAC API', () => {
  describe('Member Management', () => {
    it('should allow admin to add members', async () => {
      const response = await request(app)
        .post('/api/companies/123/members')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ email: 'user@example.com', role: 'MEMBER' });
      
      expect(response.status).toBe(201);
      expect(response.body.invitation).toBeDefined();
    });
    
    it('should prevent members from adding other members', async () => {
      const response = await request(app)
        .post('/api/companies/123/members')
        .set('Authorization', `Bearer ${memberToken}`)
        .send({ email: 'user@example.com', role: 'MEMBER' });
      
      expect(response.status).toBe(403);
    });
  });
});
```

#### Frontend Component Tests
```typescript
describe('MemberManagementPanel', () => {
  it('should show invite button for admins', () => {
    render(
      <MemberManagementPanel />,
      { initialState: { user: { role: 'ADMIN' } } }
    );
    
    expect(screen.getByText('Invite Members')).toBeInTheDocument();
  });
  
  it('should hide invite button for members', () => {
    render(
      <MemberManagementPanel />,
      { initialState: { user: { role: 'MEMBER' } } }
    );
    
    expect(screen.queryByText('Invite Members')).not.toBeInTheDocument();
  });
});
```

#### End-to-End Tests
```typescript
describe('Company Management Flow', () => {
  it('should complete full member invitation cycle', async () => {
    // Admin invites member
    await page.click('[data-testid="invite-member-button"]');
    await page.fill('[data-testid="email-input"]', 'newuser@example.com');
    await page.selectOption('[data-testid="role-select"]', 'MEMBER');
    await page.click('[data-testid="send-invitation"]');
    
    // Verify invitation was sent
    await expect(page.locator('[data-testid="invitation-sent"]')).toBeVisible();
    
    // Member accepts invitation (simulate email click)
    const invitationToken = await getLatestInvitationToken();
    await page.goto(`/invitations/${invitationToken}/accept`);
    await page.click('[data-testid="accept-invitation"]');
    
    // Verify member is added to company
    await page.goto('/companies/123/members');
    await expect(page.locator('text=newuser@example.com')).toBeVisible();
  });
});
```

## Implementation Phases

### Phase 1: Database Schema & Backend API (Week 1-2)
1. **Database Schema Updates**
   - Create new table structures for RBAC
   - Set up GSIs for efficient querying
   - Implement audit logging schema

2. **Core API Development**
   - Implement member management endpoints
   - Add invitation system APIs
   - Create permission validation middleware
   - Enhance existing company endpoints with RBAC

3. **Security Implementation**
   - JWT token enhancement with company roles
   - Permission-based middleware
   - Rate limiting and validation

### Phase 2: Frontend RBAC Components (Week 3-4)
1. **State Management**
   - Enhanced Redux slices for RBAC
   - RTK Query integration for member management
   - Permission context providers

2. **UI Components**
   - Role-based UI components
   - Member management interface
   - Invitation system UI
   - Permission guards and buttons

3. **Integration**
   - Connect frontend to new APIs
   - Implement optimistic updates
   - Error handling and loading states

### Phase 3: Advanced Features & Testing (Week 5-6)
1. **Advanced Features**
   - Bulk member operations
   - Audit trail viewing
   - Company ownership transfer
   - Advanced permission management

2. **Testing & QA**
   - Comprehensive unit testing
   - Integration testing
   - End-to-end testing
   - Security testing

3. **Documentation & Deployment**
   - API documentation updates
   - Frontend component documentation
   - Deployment and monitoring setup

## Success Criteria

### Functional Requirements
- [x] User can create companies and become automatic admin
- [x] Company creators can invite and manage members
- [x] Role-based permissions are enforced in UI and API
- [x] Members can view company information (read-only)
- [x] Audit trail tracks all admin actions
- [x] Invitation system works end-to-end

### Technical Requirements
- [x] All APIs are properly secured with JWT and RBAC
- [x] Database queries are optimized for performance
- [x] Frontend components are responsive and accessible
- [x] Test coverage exceeds 80% for critical paths
- [x] Error handling provides clear user feedback
- [x] System handles concurrent operations safely

### Performance Requirements
- [x] Company listing loads within 500ms
- [x] Member management operations complete within 2s
- [x] Invitation emails sent within 30s
- [x] System supports 100+ members per company
- [x] Database queries remain performant at scale

## Risk Mitigation

### Security Risks
- **Token Manipulation**: Implement token validation and refresh mechanisms
- **Permission Escalation**: Multiple validation layers and audit logging
- **Data Leakage**: Role-based data filtering at API level

### Performance Risks
- **Large Member Lists**: Implement pagination and virtual scrolling
- **Concurrent Updates**: Optimistic locking and conflict resolution
- **Database Hotspots**: Proper GSI design and query optimization

### User Experience Risks
- **Complex Permission Model**: Clear UI indicators and help documentation
- **Invitation Flow**: Multiple notification channels and clear status tracking
- **Role Confusion**: Intuitive role names and permission descriptions

This comprehensive specification provides a complete roadmap for implementing a robust Company Management System with role-based access control, ensuring security, scalability, and excellent user experience.