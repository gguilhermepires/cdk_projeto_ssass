# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Architecture

This is a microservices application using AWS CDK for infrastructure with a micro-frontend architecture. The project is split into backend services (`cdk backend/`) and frontend applications (`cdk front/`).

### Backend Structure
- **cdk_auth/** - Authentication service using AWS Cognito
- **cdk_back_payment/** - Payment processing service
- **cdk_backend_company/** - Company management and authentication service
- **cdk_shared_resources/** - Shared infrastructure (DynamoDB, message bus)
- **cdk_library_shared/** - Shared utilities and constructs

### Frontend Structure - Micro-Frontend Architecture
- **cdk_front_app_shell/** - Next.js 15 main application shell with Redux Toolkit (orchestrates micro-frontends)
- **cdk_front_login/** - Vite + React authentication app with ShadCN UI (embedded as iframe)
- **cdk_front_payment/** - Vite + React payment interface (embedded as iframe)
- **cdk_front_home/** - Next.js home/dashboard application (embedded as iframe)
- **cdk_front_company/** - Next.js 15 company management CRUD interface with Redux Toolkit (embedded as iframe)

## Development Commands

### Backend Services

**Authentication Service (`cdk backend/cdk_auth/`)**:
```bash
pnpm build                    # Compile TypeScript
pnpm dev                     # Development with Turbo
turbo lint                   # Run linting
pnpm format                  # Format with Prettier
npx cdk deploy --profile dev --all  # Deploy to AWS
```

**Payment Service (`cdk backend/cdk_back_payment/`)**:
```bash
pnpm build                   # Compile TypeScript
turbo build                  # Build with Turbo
turbo lint                   # Run linting
pnpm format                  # Format with Prettier
npx cdk deploy --profile dev --all  # Deploy to AWS
```

**Company Service (`cdk backend/cdk_backend_company/`)**:
```bash
pnpm build                   # Compile TypeScript
turbo build                  # Build with Turbo
npm test                     # Run Jest tests
npx cdk deploy --profile dev --all  # Deploy to AWS
```

**Shared Resources (`cdk backend/cdk_shared_resources/`)**:
```bash
turbo build                  # Build with Turbo
npm test                     # Run Jest tests
turbo build && cdk deploy --profile dev --all --require-approval never  # Build and deploy
```

### Frontend Applications

**App Shell & Company Management (Next.js)**:
```bash
npm run dev                  # Start with Turbopack
npm run build               # Production build
npm run lint                # Run ESLint
```

**Login/Payment Apps (Vite + React)**:
```bash
npm run dev                  # Start Vite dev server
npm run build               # Production build
npm run build:dev           # Development build
npm run lint                # Run ESLint
```

### Batch Scripts
- `runAll.bat` - Start all frontend services
- `runPayment.bat` - Start payment service  
- `runShell.bat` - Open development shell

## Key Technologies

**Backend**: AWS CDK 2.x, TypeScript 5.x, AWS Lambda, DynamoDB (single-table design), Cognito, Middy middleware, Zod validation, Jest, Turbo monorepo, pnpm

**Frontend**: Next.js 15 (App Router), React 18/19, Redux Toolkit, Vite, TailwindCSS, ShadCN UI, Radix UI, React Hook Form, Tanstack Query, React Router DOM

## Microservice Management

### Independent Service Architecture
Each microservice operates independently without requiring subagents or service orchestrators:

**Service Independence:**
- Each service has its own build, test, and deployment lifecycle
- Services communicate through well-defined APIs, not internal coupling
- No shared runtime dependencies between services
- Independent scaling and version management

**Development Workflow:**
- Work on services individually using their specific commands
- Use the monorepo structure for code organization, not runtime coupling
- Deploy services independently to AWS using CDK
- Test services in isolation with mocked dependencies

**Service Communication:**
- Frontend apps consume backend APIs through versioned endpoints
- No direct service-to-service communication in the current architecture
- Shared data through DynamoDB single-table design
- Event-driven patterns through AWS services (SNS/SQS) when needed

**No Subagent Pattern:**
- Each microservice is self-contained and managed through its own commands
- Use standard development tools (npm/pnpm scripts, CDK deploy) rather than orchestration
- Leverage AWS managed services for coordination when needed
- Keep services loosely coupled through API contracts

## Development Patterns

### Service Template Pattern
- Use internal RPC pattern for service definitions
- Always use `snake_case` for service names

### API Integration Rules
- Frontend strictly consumes backend public APIs (versioned endpoints `/api/{service}/v1/...`)
- JWT Bearer authentication with correlation IDs
- Idempotency keys for payment operations
- No direct database access from frontend

### Database Design
Single-table DynamoDB pattern:

**Core Entities**:
- **User**: `PK: USER#{userId}`, `SK: USER#{userId}`
- **Company**: `PK: COMPANY#{companyId}`, `SK: COMPANY#{companyId}`
  
- **Bills**: `PK: USER#{userId}`, `SK: BILL#{billId}`
- **Payments**: `PK: USER#{userId}`, `SK: PAYMENT#{paymentId}`

**Financial Management Entities**:
- **Account Balance**: `PK: USER#{userId}`, `SK: ACCOUNT#BALANCE` - User's account balance with optimistic locking
- **Transactions**: `PK: USER#{userId}`, `SK: TRANSACTION#{transactionId}` - All financial transactions (expenses, income, payments)
- **Income Records**: `PK: USER#{userId}`, `SK: INCOME#{incomeId}` - User's income sources and records
- **Expense Records**: `PK: USER#{userId}`, `SK: EXPENSE#{expenseId}` - User's expenses and spending
- **Subscriptions**: `PK: USER#{userId}`, `SK: SUBSCRIPTION#{subscriptionId}` - User's subscription records

**Company Access Patterns**:
- **Company-User Associations**: `PK: COMPANY#{companyId}`, `SK: USER#{userId}` - Links users to companies with roles/permissions

- **User-Company Memberships**: `PK: USER#{userId}`, `SK: COMPANY#{companyId}` - Tracks which companies a user has access to
- **Company Bills**: `PK: COMPANY#{companyId}`, `SK: BILL#{billId}` - Company-level billing aggregation
- **Company Payments**: `PK: COMPANY#{companyId}`, `SK: PAYMENT#{paymentId}` - Company payment history

**Supported Queries**:
- Get all companies (scan with filter)
- Get company by ID (direct lookup)
- Get all users for a company (query `PK: COMPANY#{companyId}`, `SK begins_with USER#`)

- Get all companies for a user (query `PK: USER#{userId}`, `SK begins_with COMPANY#`)
- Get company bills (query `PK: COMPANY#{companyId}`, `SK begins_with BILL#`)
- Get company payments (query `PK: COMPANY#{companyId}`, `SK begins_with PAYMENT#`)

**Financial Data Access Patterns**:
- Get user account balance (direct lookup `PK: USER#{userId}`, `SK: ACCOUNT#BALANCE`)
- Get user transactions (query `PK: USER#{userId}`, `SK begins_with TRANSACTION#`) - sorted by most recent
- Get user bills (query `PK: USER#{userId}`, `SK begins_with BILL#`)
- Get user payments (query `PK: USER#{userId}`, `SK begins_with PAYMENT#`)
- Get user income records (query `PK: USER#{userId}`, `SK begins_with INCOME#`)
- Get user expenses (query `PK: USER#{userId}`, `SK begins_with EXPENSE#`)
- Get user subscriptions (query `PK: USER#{userId}`, `SK begins_with SUBSCRIPTION#`)

**Financial Operations**:
- Account balance updates use optimistic locking with version field
- All financial operations create corresponding transaction records
- Payment operations validate account balance before processing
- Transaction categorization for expense/income tracking

### Frontend State Management
- Redux Toolkit for app shell global state
- Service layer pattern for API calls (never inline fetch)
- Environment-based configuration (no hardcoded URLs)
- Error handling with proper HTTP status codes and correlation IDs

## Environment Setup

- Node.js 20+ required
- AWS profile: Use `--profile dev` for deployments
- Package managers: pnpm (backend), npm (frontend)
- Test data: User ID `82c5dc09-f677-4728-ab8b-2bea5082ca4e`

## Company Service Integration

### Company Management System
The `cdk_backend_company` service provides comprehensive company management with the following features:

**API Endpoints (`/api`)**:
- `GET /companies` - List all companies
- `GET /companies/{id}` - Get specific company
- `POST /companies` - Create new company
- `PUT /companies/{id}` - Update company
- `DELETE /companies/{id}` - Delete company
- `POST /companies/auth` - Company authentication

**Company Schema**:
```typescript
{
  id: string,
  name: string,
  address: string,
  phone: string,
  email?: string,
  website?: string,
  status: 'ACTIVE' | 'DELETED'
}
```

**Frontend Integration**:
- Company service at `src/services/company.ts`
- Login-company page integrated with real API calls
- Dynamic company loading from backend
- JWT token storage for authenticated sessions
- Error handling and loading states

**Authentication Flow**:
1. User accesses `/login-company` route after initial login
2. Frontend fetches companies from `/api/companies`
3. User selects company and enters credentials
4. POST to `/api/companies/auth` with credentials
5. Backend validates company status and user credentials
6. Successful auth returns JWT tokens and user/company data
7. Tokens stored in localStorage for subsequent API calls

**Test Credentials**:
- Email: `admin@company.com`
- Password: `password123`
- Works with any active company ID

### Port Configuration
- **cdk_front_login**: Always starts on port 3001
- **cdk_front_payment**: Always starts on port 3002
- **cdk_front_app_shell**: Default Next.js port (usually 3000)
- **cdk_front_company**: Always starts on port 3003

## Next.js App Router Structure

The app shell follows specific organizational patterns:
- Use `src/` directory for application code
- Route groups `(folderName)` for organization without URL impact
- Colocation of components within route segments
- Redux Provider integrated in layout files
- Multiple root layouts for different sections
- Login flow: Initial auth → `/login-company` → company selection → dashboard

## System Requirements

### Member Financial Management System

As a member, I want to access and manage my financial information with the following functionalities:

**Member Authentication:**
- Log in securely to my account

**Company Selection (if applicable):**
- Select a specific company associated with my account (if I have multiple companies or profiles)

**Account Overview:**
- View my current account balance
- Access a summary of my recent transactions

**Financial Details:**
- View my detailed expenses
- View my detailed income
- View my active subscriptions

**Financial Record Management:**
- Create and record new expenses
- Create and record new subscriptions
- Create and record new income

**Financial Actions:**
- Pay recorded expenses
- Add income to my account
- Add income to my subscriptions

## Payment Service API Extensions

### Financial Management Endpoints (`/api/payment/v1/`)

**Account Management:**
- `GET /payments/account/balance` - Get current account balance
- `GET /payments/account/transactions` - Get transaction history (paginated)
- `POST /payments/account/credit` - Add funds to account balance

**Expense Management:**
- `GET /payments/expenses` - List user expenses
- `POST /payments/expenses` - Create new expense record
- `PUT /payments/expenses/{id}` - Update expense
- `POST /payments/expenses/{id}/pay` - Pay expense from account balance

**Income Management:**
- `GET /payments/income` - List user income records
- `POST /payments/income` - Record new income
- `PUT /payments/income/{id}` - Update income record
- `POST /payments/income/{id}/add-to-account` - Credit income to account

**Enhanced Subscription Management:**
- `GET /payments/subscriptions` - List active subscriptions
- `POST /payments/subscriptions` - Create subscription
- `PUT /payments/subscriptions/{id}` - Update subscription
- `POST /payments/subscriptions/{id}/pay` - Pay subscription

**Unified Transaction API:**
- `GET /payments/bills` - List all bills with filtering
- `GET /payments` - List all payments with filtering
- `POST /payments/execute` - Execute payment for a bill
- `POST /payments/bills/{billId}/cancel` - Cancel a pending bill
- `POST /payments/{userId}/bills` - Create new bill

## Implementation Details

### Data Models Added to Payment Service

```typescript
// Account with balance tracking
Account {
  userId: string,
  balance: number,
  currency: string,
  lastUpdated: string,
  version: number  // for optimistic locking
}

// Transaction record for all financial activities
Transaction {
  id: string,
  userId: string,
  type: 'EXPENSE' | 'INCOME' | 'PAYMENT' | 'ACCOUNT_CREDIT' | 'ACCOUNT_DEBIT',
  amount: number,
  description: string,
  category?: string,
  createdAt: string,
  relatedId?: string  // links to bill/payment/subscription
}

// Income tracking
Income {
  id: string,
  userId: string,
  source: string,
  amount: number,
  frequency: 'one-time' | 'monthly' | 'yearly' | 'weekly',
  receivedAt: string,
  category?: string,
  isRecurring: boolean,
  nextDueDate?: string
}

// Expense tracking
Expense {
  id: string,
  userId: string,
  description: string,
  amount: number,
  category: string,
  expenseDate: string,
  isPaid: boolean,
  relatedBillId?: string,
  dueDate?: string
}
```

### Key Financial Operations

**Account Balance Management:**
- Atomic balance updates with optimistic locking
- All operations create transaction records
- Balance validation before payments

**Expense Payment Flow:**
1. Validate account balance
2. Deduct expense amount from balance
3. Mark expense as paid
4. Create transaction record

**Income Processing:**
1. Credit amount to account balance
2. Create income record
3. Generate transaction entry
4. Handle recurring income scheduling

## Financial Management Frontend

### Payment Frontend Architecture
The `cdk_front_payment` application provides a comprehensive financial management interface:

**Key Components:**
- **Financial Dashboard** (`src/pages/Financial.tsx`) - Main financial management interface
- **Payment Service** (`src/services/paymentService.ts`) - Complete API integration layer
- **Redux State Management** - Authentication and company state
- **React Router** - Navigation with protected routes

**Financial Dashboard Features:**
- Real-time account balance display with currency formatting
- Recent transactions list with pagination
- Expense tracking with payment capabilities
- Income management with account integration
- Modal-based forms for creating expenses and income
- Company-aware financial operations

**Frontend Technologies:**
- **UI Framework**: Vite + React 18 with TypeScript
- **State Management**: Redux Toolkit with React-Redux
- **Data Fetching**: Tanstack Query (React Query) for server state
- **Routing**: React Router DOM v6
- **UI Components**: ShadCN UI with Radix UI primitives
- **Styling**: TailwindCSS with responsive design
- **Forms**: React Hook Form with Zod validation

**API Integration Patterns:**
- Environment-based configuration (`VITE_API_URL`, `VITE_PAYMENT_API_URL`)
- JWT Bearer token authentication from Redux store
- Centralized error handling with HTTP status codes
- Optimistic updates with query invalidation
- Pagination support for large datasets
- Response normalization for flexible backend formats

**Financial Management Workflow:**
1. User authentication and company selection
2. Account balance and transaction overview
3. Expense recording and payment processing
4. Income tracking and account crediting
5. Real-time balance updates with optimistic locking

**Key Frontend Features:**
- **Account Balance Card**: Live balance display with add funds functionality
- **Expense Management**: Create, view, and pay expenses directly from account
- **Income Tracking**: Record income with frequency settings and account integration
- **Transaction History**: Chronological list of all financial activities
- **Responsive Design**: Mobile-first approach with TailwindCSS
- **Loading States**: Skeleton screens and loading indicators
- **Error Boundaries**: Graceful error handling with user feedback

## Company Management Frontend

### Company Frontend Architecture
The `cdk_front_company` application provides a comprehensive business management interface combining company CRUD operations with financial management:

**Key Components:**
- **Business Management Dashboard** (`src/app/page.tsx`) - Tabbed interface with company and financial management
- **Company Service** (`src/services/companyService.ts`) - Complete company API integration layer
- **Payment Service** (`src/services/paymentService.ts`) - Financial management API integration with RTK Query
- **Financial Dashboard** (`src/components/FinancialDashboard.tsx`) - Comprehensive financial management interface
- **Redux State Management** - Company state management with Redux Toolkit and Payment API integration
- **Next.js App Router** - Modern routing with app directory structure

**Business Management Features:**
- **Company CRUD**: Complete company listing, creation, editing, and deletion with search and filtering
- **Financial Dashboard**: Account balance management, expense tracking, income recording, and transaction history
- **Tabbed Interface**: Seamless switching between company management and financial operations
- **Real-time Updates**: Live data synchronization with backend APIs
- **Responsive Design**: Mobile-first approach with consistent UI patterns

**Financial Management Integration:**
- **Account Management**: View balance, add funds, track transaction history
- **Expense Tracking**: Create, view, and pay expenses directly from account balance
- **Income Recording**: Record income with frequency settings and account integration
- **Payment Processing**: Direct expense payment with account balance validation
- **Transaction History**: Chronological view of all financial activities

**Frontend Technologies:**
- **UI Framework**: Next.js 15 with App Router and TypeScript
- **State Management**: Redux Toolkit with React-Redux and RTK Query for server state
- **Data Fetching**: Tanstack Query (React Query) and RTK Query for optimal caching
- **UI Components**: ShadCN UI with Radix UI primitives (Tabs, Select, Dialog components)
- **Styling**: TailwindCSS with responsive design and consistent theming
- **Forms**: React Hook Form with Zod validation for both company and financial forms
- **Icons**: Lucide React for consistent iconography across all interfaces

**API Integration Patterns:**
- **Dual API Configuration**: Company API (`NEXT_PUBLIC_API_URL`) and Payment API (`NEXT_PUBLIC_PAYMENT_API_URL`)
- **JWT Bearer Authentication**: Automatic token injection from Redux store for both APIs
- **RTK Query Integration**: Efficient caching, background updates, and optimistic updates for financial data
- **Centralized Error Handling**: Consistent error handling with toast notifications
- **Response Normalization**: Flexible backend format support with array fallbacks
- **Environment-based Configuration**: Separate development and production API endpoints

**Integrated Workflow:**
1. **Authentication**: User authentication with company selection and JWT token storage
2. **Company Management**: Browse, create, edit, and delete companies with real-time updates
3. **Financial Operations**: Switch to financial dashboard for comprehensive money management
4. **Account Management**: View balance, add funds, and track all financial transactions
5. **Expense Processing**: Create expenses and pay them directly from account balance
6. **Income Tracking**: Record income and optionally add to account balance
7. **Data Synchronization**: Real-time updates across both company and financial data

**Development Setup:**
```bash
cd cdk_front_company
npm install                  # Install dependencies
npm run dev                  # Start development server on port 3003
npm run build               # Production build
npm run lint                # Run ESLint
```

**Enhanced Integration Features:**
- **Tabbed Navigation**: Seamless UX between company management and financial dashboard
- **Unified State Management**: Single Redux store managing both company and payment data
- **Dual API Integration**: Company service for CRUD operations, Payment service for financial management
- **Real-time Balance Updates**: Account balance updates immediately after financial transactions
- **Comprehensive Financial Tracking**: Full expense/income lifecycle from creation to payment/processing
- **Optimistic UI Updates**: Immediate UI feedback with automatic error rollback
- **Currency Formatting**: Dynamic currency display based on account settings
- **Loading States**: Sophisticated skeleton screens and loading indicators for all operations
- **Error Boundaries**: Graceful degradation with user-friendly error messages