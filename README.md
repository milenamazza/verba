# Verba - Telecom Database Project

## Project Description
Verba is a comprehensive database system designed for a telecommunications company. It manages customer data, employee information, SIM cards, phone plans, banking accounts, and communication records (calls, messages, and data usage).

## Key Features
- **Customer Management**: Track personal details, SIM cards, and banking information
- **Employee Records**: Manage employment history, qualifications, and current positions
- **SIM Card Tracking**: Monitor active and inactive SIMs with activation/expiration dates
- **Tariff Plans**: Manage various phone plans with minutes, messages, and data allowances
- **Communication Logs**: Record calls, messages, and data usage
- **Financial Transactions**: Track recharges and payments

## Database Structure
The database follows a relational model with:
- 15+ entities (Person, Employee, SIM, Tariff, etc.)
- Complex relationships between entities
- Support for inheritance (IS-A relationships)
- Constraints and triggers for data integrity

## Technical Implementation
- **Database Engine**: PostgreSQL
- **Key Features**:
  - Complex constraints and triggers
  - Stored procedures for business logic
  - Views for simplified querying
  - Optimized schema design

## Project Structure
```
verba-database/
├── documentation/          # Project documentation and reports
├── sql/                   # SQL scripts
│   ├── schema/            # Database schema definition
│   ├── triggers/          # Database triggers
│   ├── procedures/        # Stored procedures
│   └── queries/           # Complex queries and views
└── README.md              # This file
```

## Installation
1. Clone the repository
2. Execute SQL scripts in order:
   - Schema creation
   - Triggers and procedures
   - Sample data (if available)

## Usage Examples
The database supports operations like:
- Customer registration
- SIM activation/deactivation
- Plan subscription management
- Communication record keeping
- Employee management
- Financial transactions

## Key SQL Features
- Complex constraints (age verification, date validation)
- Triggers for automatic operations (balance updates, SIM deactivation)
- Optimized queries with views
- Transaction management

## Requirements
- PostgreSQL 12+ (or compatible RDBMS)
- Basic SQL knowledge for querying

## Documentation
The full project documentation is available in the documentation folder, including:
- Entity-Relationship diagrams
- Schema documentation
- Operation specifications
- Query explanations

## License
This project is for educational purposes. Please contact the author for usage permissions.
