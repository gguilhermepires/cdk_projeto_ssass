# Suggested Commands

## Development Commands (Windows)

### Frontend Applications
```bash
# Start all frontend services
cd "cdk front"
runAll.bat

# Individual services
runLogin.bat     # Login app (port 3001)
runPayment.bat   # Payment app (port 3002)
runCompany.bat   # Company app (port 3003)
runShell.bat     # App shell (port 3000)

# Next.js applications (App Shell, Company, Home)
npm run dev      # Start development server with Turbopack
npm run build    # Production build
npm run lint     # Run ESLint

# Vite applications (Login, Payment)
npm run dev      # Start Vite development server
npm run build    # Production build
npm run build:dev # Development build
npm run lint     # Run ESLint
```

### Backend Services
```bash
# Authentication Service (cdk backend/cdk_auth/)
pnpm build       # Compile TypeScript
pnpm dev         # Development with Turbo
turbo lint       # Run linting
pnpm format      # Format with Prettier
npx cdk deploy --profile dev --all  # Deploy to AWS

# Payment Service (cdk backend/cdk_back_payment/)
pnpm build       # Compile TypeScript
turbo build      # Build with Turbo
turbo lint       # Run linting
pnpm format      # Format with Prettier
npx cdk deploy --profile dev --all  # Deploy to AWS

# Company Service (cdk backend/cdk_backend_company/)
pnpm build       # Compile TypeScript
turbo build      # Build with Turbo
npm test         # Run Jest tests
npx cdk deploy --profile dev --all  # Deploy to AWS

# Shared Resources (cdk backend/cdk_shared_resources/)
turbo build      # Build with Turbo
npm test         # Run Jest tests
turbo build && cdk deploy --profile dev --all --require-approval never  # Build and deploy
```

### Utility Commands (Windows)
```cmd
# File operations
dir              # List files (equivalent to ls)
cd               # Change directory
type             # Display file contents (equivalent to cat)
findstr          # Search text in files (equivalent to grep)
where            # Find file locations (equivalent to which)

# Git operations
git status       # Check repository status
git add .        # Add all changes
git commit -m    # Commit changes
git push         # Push to remote
git pull         # Pull from remote

# Package management
npm install      # Install Node.js dependencies
npm update       # Update dependencies
pnpm install     # Install with pnpm (backend)
pnpm update      # Update with pnpm
```

## Testing and Quality Commands
```bash
# Testing
npm test         # Run Jest tests
npm run test:watch  # Run tests in watch mode

# Linting and Formatting
npm run lint     # Run ESLint
turbo lint       # Run linting with Turbo
pnpm format      # Format with Prettier

# Building
npm run build    # Build for production
turbo build      # Build with Turbo
```

## Environment Setup
```bash
# AWS Profile
--profile dev    # Use development AWS profile for deployments

# Node.js version
# Requires Node.js 20+

# Test data
# Lodge ID: lodge-demo-001
# User ID: 82c5dc09-f677-4728-ab8b-2bea5082ca4e
```