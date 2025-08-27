# Project Overview

## Purpose
This is a comprehensive microservices application for financial and company management with a micro-frontend architecture. The system provides:
- Company management (CRUD operations)
- Financial management (account balance, expenses, income, subscriptions)
- User authentication with company selection
- Payment processing and transaction tracking

## Architecture
- **Backend**: AWS CDK microservices with DynamoDB single-table design
- **Frontend**: Micro-frontend architecture with multiple independent applications
- **Authentication**: JWT-based with AWS Cognito integration
- **Database**: DynamoDB with optimized access patterns for financial and company data
- **Infrastructure**: AWS CDK 2.x for infrastructure as code

## Key Services
- **Authentication Service**: AWS Cognito integration
- **Payment Service**: Financial transactions, account management
- **Company Service**: Company CRUD operations and authentication
- **Lodge Service**: Accommodation management
- **Shared Resources**: DynamoDB tables, message bus

## Frontend Applications
- **App Shell**: Next.js 15 main application (port 3000)
- **Login**: Vite + React authentication (port 3001) 
- **Payment**: Vite + React financial management (port 3002)
- **Company**: Next.js 15 company management (port 3003)
- **Home**: Next.js dashboard application

## Tech Stack
**Backend**: TypeScript 5.x, AWS CDK 2.x, AWS Lambda, DynamoDB, AWS Cognito, Middy, Zod, Jest
**Frontend**: Next.js 15, React 18/19, Redux Toolkit, Vite, TailwindCSS, ShadCN UI, Radix UI
**Tooling**: Turbo monorepo, pnpm (backend), npm (frontend)