# Code Style and Conventions

## General Patterns
- **Service Template Pattern**: Use internal RPC pattern for service definitions
- **Naming Convention**: Always use `snake_case` for service names
- **TypeScript**: Strict typing with TypeScript 5.x throughout the codebase
- **No Hardcoded URLs**: Environment-based configuration for all API endpoints

## API Integration Rules
- **Versioned APIs**: Frontend consumes backend public APIs with versioned endpoints `/api/{service}/v1/...`
- **Authentication**: JWT Bearer authentication with correlation IDs
- **Error Handling**: Proper HTTP status codes with correlation IDs
- **Idempotency**: Idempotency keys for payment operations
- **Service Layer Pattern**: API calls abstracted into service layers (never inline fetch)

## Database Design
- **Single-table DynamoDB**: Optimized access patterns with composite keys
- **Partition Keys**: `PK: ENTITY#{entityId}`, `SK: ENTITY#{entityId}` pattern
- **Access Patterns**: Designed for specific query needs (no scans except filtered)
- **Optimistic Locking**: Version fields for balance updates and concurrent operations

## Frontend Architecture
- **State Management**: Redux Toolkit for global state
- **Component Structure**: ShadCN UI with Radix UI primitives
- **Styling**: TailwindCSS with responsive design patterns
- **Forms**: React Hook Form with Zod validation
- **Routing**: Next.js App Router for Next.js apps, React Router DOM for Vite apps

## File Organization
- **Next.js**: Use `src/` directory, route groups `(folderName)` for organization
- **Component Colocation**: Components within route segments
- **Service Files**: Centralized service files (`src/services/`)
- **Redux Structure**: Separate slices for different domains

## Authentication Flow
1. Initial auth → `/login-company` → company selection → dashboard
2. JWT tokens stored in localStorage
3. Redux state management for auth across micro-frontends
4. PostMessage communication between apps for auth sharing

## Code Quality
- **TypeScript Strict Mode**: All projects use strict TypeScript
- **ESLint Configuration**: Consistent linting across all frontends
- **Prettier Formatting**: Code formatting for backends
- **Testing**: Jest for backend testing
- **Error Boundaries**: Graceful error handling with user feedback

## Environment Variables
- **Frontend**: `NEXT_PUBLIC_*` for Next.js, `VITE_*` for Vite apps
- **Backend**: AWS CDK environment-specific configurations
- **API URLs**: Separate development and production endpoints

## Port Configuration (Fixed)
- App Shell: 3000 (default Next.js)
- Login: 3001
- Payment: 3002  
- Company: 3003