# Task: Company Management System with Role-Based Access Control

## Executive Summary

Implement a comprehensive Company Management System with role-based permissions, extending the existing company CRUD functionality to include user roles, permissions management, and secure access control across both backend and frontend layers.

## Core Objectives

- **Company Creation**: Users can create companies and are automatically assigned admin role
- **Role Management**: Implement admin/member roles with appropriate permissions
- **Company Viewing**: Secure company details viewing based on user roles
- **Admin Privileges**: Restrict company editing and member management to admins only
- **Member Management**: Admins can invite, assign roles, and manage company members

## Technical Requirements

### Backend Architecture (AWS CDK + Lambda + DynamoDB)

#### Database Schema Extensions

**Enhanced Entity: Company Members with Roles & Audit Trail**
```typescript
// Company-User Association (Enhanced with Audit & Versioning)
{
  PK: "COMPANY#{companyId}",
  SK: "USER#{userId}",
  GSI1PK: "USER#{userId}",
  GSI1SK: "COMPANY#{companyId}",
  GSI2PK: "ROLE#{role}",
  GSI2SK: "COMPANY#{companyId}#USER#{userId}",
  role: "ADMIN" | "MEMBER",
  permissions: string[], // ["READ", "WRITE", "MANAGE_MEMBERS"]
  invitedBy: string, // userId of admin who invited
  joinedAt: string,
  lastModifiedBy: string,
  lastModifiedAt: string,
  version: number, // for optimistic locking
  status: "ACTIVE" | "PENDING" | "INACTIVE"
}

// User-Company Membership (Enhanced)
{
  PK: "USER#{userId}",
  SK: "COMPANY#{companyId}",
  role: "ADMIN" | "MEMBER",
  permissions: string[],
  lastAccessed: string,
  status: "ACTIVE" | "PENDING" | "INACTIVE"
}

// Company Invitations
{
  PK: "COMPANY#{companyId}",
  SK: "INVITATION#{invitationId}",
  email: string,
  role: "ADMIN" | "MEMBER",
  invitedBy: string,
  invitedAt: string,
  expiresAt: string,
  status: "PENDING" | "ACCEPTED" | "EXPIRED" | "CANCELLED"
}

// Company Settings (Role-Based Feature Toggles)
{
  PK: "COMPANY#{companyId}",
  SK: "SETTINGS",
  allowMemberInvites: boolean,
  requireAdminApproval: boolean,
  maxMembers: number,
  featureToggles: Record<string, boolean>,
  lastModifiedBy: string,
  lastModifiedAt: string
}

// Company Activity Log (Audit Trail)
{
  PK: "COMPANY#{companyId}",
  SK: "ACTIVITY#{timestamp}#{activityId}",
  GSI1PK: "USER#{userId}",
  GSI1SK: "ACTIVITY#{timestamp}",
  userId: string,
  action: string, // "MEMBER_INVITED", "ROLE_CHANGED", "MEMBER_REMOVED"
  details: Record<string, any>,
  timestamp: string,
  ipAddress: string
}
```

#### API Endpoints Implementation

**Company Management Endpoints (`/api/companies/v1/`)**

1. **Company CRUD with Authorization**
   - `GET /companies` - List user's companies with role information
   - `GET /companies/{id}` - Get company details (requires membership)
   - `POST /companies` - Create company (creator becomes admin)
   - `PUT /companies/{id}` - Update company (admin only)
   - `DELETE /companies/{id}` - Soft delete company (admin only)

2. **Member Management Endpoints**
   - `GET /companies/{id}/members` - List company members with pagination (members can view)
   - `POST /companies/{id}/members/invite` - Invite new member (admin only)
   - `POST /companies/{id}/members/bulk-invite` - Bulk invite members (admin only)
   - `PUT /companies/{id}/members/{userId}` - Update member role (admin only)
   - `PUT /companies/{id}/members/bulk-update` - Bulk update member roles (admin only)
   - `DELETE /companies/{id}/members/{userId}` - Remove member (admin only)
   - `DELETE /companies/{id}/members/bulk-remove` - Bulk remove members (admin only)
   - `POST /companies/{id}/members/join` - Join company via invitation link

3. **Permission Management Endpoints**
   - `GET /companies/{id}/permissions` - Get user's permissions for company
   - `PUT /companies/{id}/members/{userId}/permissions` - Update member permissions (admin only)

4. **Invitation Management Endpoints**
   - `GET /companies/{id}/invitations` - List pending invitations (admin only)
   - `POST /companies/{id}/invitations/{invitationId}/resend` - Resend invitation (admin only)
   - `DELETE /companies/{id}/invitations/{invitationId}` - Cancel invitation (admin only)

5. **Company Activity & Audit Endpoints**
   - `GET /companies/{id}/activity` - Get company activity feed (admin only)
   - `GET /companies/{id}/audit-log` - Get detailed audit log (admin only)
   - `POST /companies/{id}/webhooks` - Configure role change webhooks (admin only)

#### Authorization Middleware

**Role-Based Access Control**
```typescript
// Permission definitions
enum Permission {
  READ_COMPANY = "READ_COMPANY",
  WRITE_COMPANY = "WRITE_COMPANY",
  MANAGE_MEMBERS = "MANAGE_MEMBERS",
  VIEW_MEMBERS = "VIEW_MEMBERS",
  INVITE_MEMBERS = "INVITE_MEMBERS"
}

// Role definitions
const ROLE_PERMISSIONS = {
  ADMIN: [
    Permission.READ_COMPANY,
    Permission.WRITE_COMPANY,
    Permission.MANAGE_MEMBERS,
    Permission.VIEW_MEMBERS,
    Permission.INVITE_MEMBERS
  ],
  MEMBER: [
    Permission.READ_COMPANY,
    Permission.VIEW_MEMBERS
  ]
};
```

**Middleware Implementation**
- JWT token validation with user context
- Company membership verification
- Permission-based access control
- Audit logging for admin actions

### Frontend Architecture (Next.js 15 + Redux Toolkit)

#### Component Structure

**Enhanced Company Management Interface**

1. **Company Dashboard** (`src/components/CompanyDashboard.tsx`)
   - Company list with role indicators
   - Quick actions based on user permissions
   - Member count and recent activity

2. **Company Details View** (`src/components/CompanyDetails.tsx`)
   - Company information display
   - Edit mode for admins only
   - Member management section

3. **Member Management** (`src/components/MemberManagement.tsx`)
   - Member list with roles and permissions (with pagination)
   - Invite member form (admin only)
   - Bulk member operations interface (admin only)
   - Role assignment interface (admin only)
   - Remove member functionality with confirmation (admin only)
   - Member activity timeline view

4. **Role-Based UI Components**
   - `AdminOnlyWrapper` - Conditionally render admin features
   - `PermissionWrapper` - Show/hide based on specific permissions
   - `RoleBadge` - Display user's role with consistent styling
   - `MemberActionMenu` - Dropdown menu for admin member operations
   - `CompanyCard` - Company display card with role indicators
   - `LoadingSkeleton` - Loading states for member operations

#### State Management (Redux Toolkit)

**Enhanced Company State**
```typescript
interface CompanyState {
  companies: Company[];
  selectedCompany: Company | null;
  userRole: string | null;
  userPermissions: string[];
  members: CompanyMember[];
  invitations: CompanyInvitation[];
  loading: {
    companies: boolean;
    members: boolean;
    invitations: boolean;
  };
  error: string | null;
}
```

**RTK Query API Slices**
- `companyApi` - Company CRUD operations
- `memberApi` - Member management operations
- `invitationApi` - Invitation management operations

#### User Interface Requirements

**Company List View**
- Card-based layout with company name, role badge, member count
- Search and filter by role
- Quick actions (view, edit for admins)
- Create new company button

**Company Details View**
- Tabbed interface: Details, Members, Settings
- Edit mode toggle for admins
- Member list with role indicators
- Invite member button (admin only)

**Member Management Interface**
- Data table with member info, roles, join date
- Role dropdown for admins to change member roles
- Remove member confirmation dialog
- Bulk actions for member management

**Permission-Based UI**
- Visual indicators for admin-only features
- Disabled states for unauthorized actions
- Conditional rendering based on permissions
- Clear error messages for unauthorized attempts

### Authentication & Authorization

#### JWT Token Enhancement

**Enhanced Token Payload**
```typescript
interface JWTPayload {
  userId: string;
  email: string;
  companies: {
    [companyId: string]: {
      role: string;
      permissions: string[];
      status: string;
    }
  };
  iat: number;
  exp: number;
}
```

#### Frontend Authorization

**Permission Hooks**
```typescript
// Custom hooks for permission checking
useHasPermission(companyId: string, permission: Permission): boolean
useIsAdmin(companyId: string): boolean
useCompanyRole(companyId: string): string | null
```

**Route Protection**
- Company-specific route guards
- Role-based page access
- Redirect to appropriate views based on permissions

#### Backend Authorization

**Middleware Chain**
1. JWT validation and decoding
2. User context extraction
3. Company membership verification
4. Permission checking
5. Audit logging (for admin actions)

## Testing Strategy

### Backend Unit Tests

**API Endpoint Tests**
```typescript
describe('Company Member Management API', () => {
  describe('POST /companies/{id}/members/invite', () => {
    it('should allow admin to invite new member');
    it('should reject non-admin invitation attempts');
    it('should validate email format');
    it('should prevent duplicate invitations');
    it('should create proper invitation record');
  });

  describe('PUT /companies/{id}/members/{userId}', () => {
    it('should allow admin to change member role');
    it('should reject non-admin role changes');
    it('should prevent self-demotion of last admin');
    it('should update permissions correctly');
  });
});
```

**Permission Middleware Tests**
```typescript
describe('Permission Middleware', () => {
  it('should verify company membership correctly');
  it('should check role-based permissions');
  it('should handle missing permissions gracefully');
  it('should log admin actions for audit');
});
```

**Database Operation Tests**
```typescript
describe('Company Member Repository', () => {
  it('should create company with admin user correctly');
  it('should handle role updates atomically');
  it('should maintain data consistency across tables');
  it('should handle invitation lifecycle properly');
  it('should handle concurrent role changes with optimistic locking');
  it('should test invitation expiration scenarios');
  it('should stress test member list queries with large datasets');
  it('should test permission inheritance edge cases');
});
```

### Frontend Unit Tests

**Component Tests**
```typescript
describe('MemberManagement Component', () => {
  it('should display members list correctly');
  it('should show admin controls only for admins');
  it('should handle role changes properly');
  it('should confirm member removal');
  it('should display loading skeletons during operations');
  it('should show optimistic UI updates');
  it('should handle error states gracefully');
});

describe('Permission Hooks', () => {
  it('should return correct permissions for user role');
  it('should handle missing company membership');
  it('should update when role changes');
  it('should handle permission hook edge cases');
  it('should maintain state during concurrent updates');
});

describe('Role-Based Components', () => {
  it('should render RoleBadge with correct styling');
  it('should show/hide PermissionWrapper content correctly');
  it('should handle MemberActionMenu permissions');
  it('should test accessibility of role indicators');
});
```

**Redux State Tests**
```typescript
describe('Company State Management', () => {
  it('should update member roles correctly');
  it('should handle invitation creation');
  it('should maintain consistent state during operations');
});
```

### MCP Browser Testing

**Automated Browser Testing**
```typescript
describe('Company Management Browser Tests', () => {
  it('should complete company creation flow');
  it('should restrict non-admin access to edit features');
  it('should handle member invitation workflow');
  it('should display appropriate UI for different roles');
  it('should maintain state across page navigation');
  it('should test role indicator rendering across browsers');
  it('should verify member management modals on mobile');
  it('should test keyboard navigation for admin controls');
  it('should validate form field enabling/disabling by role');
});
```

**Cross-Browser Compatibility**
- Chrome, Firefox, Safari testing with role-specific features
- Mobile responsive design validation for member management
- Accessibility compliance testing with screen readers
- Touch interface testing for mobile admin operations

### End-to-End Testing

**Complete User Flow Testing**
1. **Company Creation Flow**
   - User creates company → becomes admin
   - Company appears in user's company list
   - Admin can access all management features
   - Concurrent company creation by different users

2. **Member Management Flow**
   - Admin invites new member via email
   - Invited user receives and accepts invitation
   - Member can view company but not edit
   - Admin can change member to admin role
   - New admin can manage other members
   - Bulk member operations workflow

3. **Permission Enforcement Flow**
   - Member attempts unauthorized action → blocked with clear feedback
   - Admin performs same action → succeeds
   - UI updates appropriately based on role changes
   - Last admin role removal prevention testing

4. **Cross-Session & Concurrency Testing**
   - Multiple admins making concurrent role changes
   - Invitation link validation across different browser sessions
   - Company switching workflow with role persistence
   - Permission consistency across browser refreshes

5. **Edge Case & Performance Testing**
   - Large member list rendering and pagination
   - Invitation expiration and cleanup
   - Network failure during role changes
   - Data consistency during rapid role transitions

## Implementation Phases

### Phase 1: Database Schema & Backend Infrastructure (Week 1-2)

**Dependencies:** None - Foundation phase
**Risk Level:** Medium - Database migrations and schema design critical

**Deliverables:**
- Enhanced DynamoDB table structure with GSI optimization
- RBAC middleware with optimistic locking implementation
- Company creation with automatic admin assignment
- JWT token enhancement with role payload
- Basic audit logging infrastructure

**Detailed Timeline:**
- Days 1-3: Database schema design and migration scripts
- Days 4-6: RBAC middleware implementation and testing
- Days 7-10: JWT enhancement and company creation logic
- Days 11-14: Integration testing and bug fixes

**Acceptance Criteria:**
- [ ] Database schema supports efficient role-based queries with GSI
- [ ] Company creation automatically assigns admin role with version control
- [ ] JWT tokens include complete company role and permission information
- [ ] Basic permission checking middleware handles edge cases
- [ ] Audit logging captures all role changes with proper attribution

**Risk Mitigation:**
- Database migration rollback plan prepared
- Performance testing with large datasets
- Backup strategy for production data

### Phase 2: Member Management API & Business Logic (Week 2-3)

**Dependencies:** Phase 1 completion
**Risk Level:** High - Complex business rules and concurrency handling

**Deliverables:**
- Complete member management endpoint suite
- Invitation system with lifecycle management
- Bulk operations with transaction handling
- Permission-based access control enforcement
- Enhanced audit logging with activity feeds

**Detailed Timeline:**
- Days 1-4: Core member management CRUD operations
- Days 5-7: Invitation system implementation
- Days 8-10: Bulk operations and concurrency handling
- Days 11-14: Permission enforcement and audit enhancements

**Acceptance Criteria:**
- [ ] Admins can invite/remove/promote members with validation
- [ ] Members have read-only access with proper error handling
- [ ] Invitation lifecycle works with expiration and cleanup
- [ ] All admin actions logged with IP and timestamp
- [ ] Bulk operations handle partial failures gracefully
- [ ] Concurrency conflicts resolved with optimistic locking

**Risk Mitigation:**
- Load testing for bulk operations
- Race condition testing with automated scenarios
- Database transaction failure handling

### Phase 3: Frontend Architecture & Core UI (Week 3-4)

**Dependencies:** Phase 2 API completion
**Risk Level:** Medium - Complex state management and UI consistency

**Deliverables:**
- Enhanced Redux Toolkit store with RTK Query integration
- Reusable permission-based UI component library
- Company details and member management interfaces
- Role-based navigation with route guards
- Loading states and error boundaries

**Detailed Timeline:**
- Days 1-3: Redux store enhancement and API integration
- Days 4-7: Reusable UI component development
- Days 8-11: Member management interface implementation
- Days 12-14: Navigation, routing, and error handling

**Acceptance Criteria:**
- [ ] UI accurately reflects user's current role and permissions
- [ ] Admin-only features conditionally rendered with loading states
- [ ] Member management interface handles all CRUD operations
- [ ] State management maintains consistency during role changes
- [ ] Error boundaries provide meaningful feedback
- [ ] Mobile responsive design works across all components

**Risk Mitigation:**
- Component testing in isolation
- Cross-browser compatibility validation
- Performance monitoring for large member lists

### Phase 4: Advanced Features & User Experience (Week 4-5)

**Dependencies:** Phase 3 core UI completion
**Risk Level:** Low - Enhancement and polish phase

**Deliverables:**
- Bulk member operations with progress indicators
- Advanced invitation management (resend, cancel, bulk)
- Activity feed and audit trail interfaces
- Enhanced error handling and user feedback
- Accessibility improvements and keyboard navigation

**Detailed Timeline:**
- Days 1-4: Bulk operations UI and backend integration
- Days 5-7: Advanced invitation management features
- Days 8-10: Activity feed and audit interfaces
- Days 11-14: UX polish, accessibility, and optimization

**Acceptance Criteria:**
- [ ] Bulk member role changes work with progress tracking
- [ ] Invitation management provides complete lifecycle control
- [ ] Activity feed shows real-time company actions
- [ ] Error handling provides actionable user guidance
- [ ] Accessibility standards met for all role-based features
- [ ] Keyboard navigation works for all admin operations

**Risk Mitigation:**
- User acceptance testing with real scenarios
- Accessibility audit with screen readers
- Performance optimization for activity feeds

### Phase 5: Testing, Security & Production Deployment (Week 5-6)

**Dependencies:** Phase 4 feature completion
**Risk Level:** High - Production readiness and security validation

**Deliverables:**
- Comprehensive automated test suite (Unit, Integration, E2E)
- Security audit and penetration testing
- Performance optimization and monitoring
- Production deployment with rollback capabilities
- Documentation and operational runbooks

**Detailed Timeline:**
- Days 1-3: Test suite completion and automation setup
- Days 4-6: Security audit and vulnerability assessment
- Days 7-9: Performance testing and optimization
- Days 10-12: Production deployment and monitoring setup
- Days 13-14: Documentation and team handover

**Acceptance Criteria:**
- [ ] >90% test coverage on critical role-based paths
- [ ] All MCP browser tests pass across target environments
- [ ] Security audit shows no high/critical vulnerabilities
- [ ] Performance benchmarks met under load
- [ ] Production deployment successful with zero downtime
- [ ] Monitoring and alerting configured for role operations

**Risk Mitigation:**
- Blue-green deployment strategy
- Automated rollback procedures
- Load testing with production data volumes
- Security scanning in CI/CD pipeline

### Cross-Phase Dependencies & Critical Path

**Critical Path Analysis:**
1. Database schema → JWT enhancement → API development → UI implementation → Testing
2. Parallel development possible for: UI components (Phase 3) can start with mocked APIs
3. Testing automation setup should begin in Phase 2

**Inter-Phase Communication:**
- Weekly cross-team sync meetings
- API contract documentation maintained throughout
- Continuous integration with feature flags for gradual rollout

## Definition of Done

**User Stories Completion:**
- [ ] Users can create companies and become admins automatically
- [ ] Companies can be viewed with appropriate permission levels
- [ ] Only admins can edit company information
- [ ] Only admins can manage members and assign roles
- [ ] Members have read-only access as expected
- [ ] Unauthorized actions are properly blocked and logged

**Technical Completion:**
- [ ] All API endpoints implemented with proper authorization
- [ ] Frontend components handle all permission states
- [ ] Database schema supports role-based queries efficiently
- [ ] JWT tokens carry complete permission context
- [ ] Audit logging captures all admin actions

**Quality Assurance:**
- [ ] Unit test coverage >85% for new code
- [ ] All MCP browser tests pass across target browsers
- [ ] End-to-end user flows work seamlessly
- [ ] Performance benchmarks met
- [ ] Security audit passes
- [ ] Accessibility standards compliance verified

## Success Metrics

**Functional Metrics:**
- Company creation success rate: >99%
- Member invitation acceptance rate: >80%
- Zero unauthorized access attempts succeed
- Admin action audit log completeness: 100%

**Performance Metrics:**
- Company list load time: <2 seconds
- Member management operations: <1 second response
- Database query efficiency: <100ms average
- Frontend bundle size impact: <10% increase

**User Experience Metrics:**
- Task completion rate for admin flows: >95%
- User error rate in permission-restricted areas: <5%
- Support tickets related to access confusion: <2 per month

## Security Considerations & Compliance

### Security Requirements

**Authentication & Authorization**
- JWT tokens with short expiration (15-30 minutes) and refresh token rotation
- Multi-factor authentication for admin role assignments
- Session management with proper logout and token invalidation
- Rate limiting on invitation endpoints to prevent abuse
- Input validation and sanitization for all user inputs

**Data Protection**
- Encryption at rest for all company and member data
- Encryption in transit with TLS 1.3 minimum
- Personal data anonymization in audit logs
- Secure deletion of member data upon removal
- Data retention policies for audit trails

**Access Control Security**
- Principle of least privilege enforcement
- Regular access reviews and role auditing
- Automated detection of privilege escalation attempts
- Prevention of last admin role removal
- IP-based access restrictions for sensitive operations

**Vulnerability Prevention**
- SQL injection prevention (parameterized queries)
- Cross-site scripting (XSS) protection
- Cross-site request forgery (CSRF) tokens
- Content Security Policy (CSP) implementation
- Regular dependency vulnerability scanning

### Compliance Framework

**Data Privacy Compliance (GDPR/CCPA)**
- User consent management for role-based data processing
- Right to be forgotten implementation
- Data portability for company member data
- Privacy by design in role management features
- Data Processing Impact Assessment (DPIA) documentation

**Audit & Compliance Logging**
- Immutable audit trail for all role changes
- Compliance reporting capabilities
- Log retention according to regulatory requirements
- Automated compliance monitoring and alerting
- Regular audit log integrity verification

**Security Monitoring & Incident Response**
- Real-time monitoring of unauthorized access attempts
- Automated alerting for suspicious role change patterns
- Incident response procedures for data breaches
- Security event correlation and analysis
- Regular security testing and vulnerability assessments

This comprehensive task specification provides clear implementation guidance while ensuring robust role-based access control, thorough testing coverage, seamless user experience, and enterprise-grade security across the Company Management System.