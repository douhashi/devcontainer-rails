# Testing Strategy

## Overview

This document defines the testing strategy for the Hirame project. By clearly separating test types and defining the scope of responsibility for each test, we build an efficient and maintainable test suite.

## Test Types and Selection Flow

### Role of Each Test Type

- **Unit Test**: Business logic in models, libraries, service classes, etc.
- **Request Spec**: Basic HTTP operations, authentication, simple form operations
- **System Spec**: JavaScript-required dynamic UI, complex user interactions

### Test Selection Flowchart

```
Need to write a test?
    ↓
Logic that can be unit tested?
    ├─ Yes → Unit Test
    └─ No
        ↓
    Requires custom JavaScript execution?
        ├─ Yes → System Spec
        └─ No
            ↓
        Only browser standard features (confirm, etc.)?
            ├─ Yes → Request Spec (can be handled with Turbo)
            └─ No
                ↓
            Complex UI interactions?
                ├─ Yes → System Spec
                └─ No → Request Spec
```

This strategy significantly improves test suite execution speed and stability. In particular, by properly testing business logic with unit tests, we can build a fast and reliable test suite.

## Important Notes

### Rules to Always Follow

- **Always follow test type classifications** - Clarify the scope of responsibility for each test level and write tests at the appropriate level
- **Minimize use of mocks/stubs** - Use only when testing integration with external systems or middleware is necessary AND actual external systems/middleware are unavailable
- **Avoid duplicate test cases** - When the same behavior is covered by multiple tests, consolidate them to prevent meaningless test suite bloat

### Test Design Principles

- Each test must be independently executable
- Tests must not depend on execution order
- Test data must be explicitly prepared in each test
- Test names must clearly indicate what is being tested

## Test Types and Usage

### Unit Test

**Purpose**: Verify business logic in models, libraries, service classes, etc. in isolation

**When to use**:
- Input/output verification of custom methods in models
- Business logic in service classes
- Behavior verification of library/helper methods
- Complex scopes and query methods
- Custom validation logic
- Custom processing in callbacks

**When to minimize testing**:
- Rails standard validations (presence, uniqueness, length, etc.)
- Simple association definitions
- Parts using only Rails-provided standard features

**Characteristics**:
- Fastest execution
- Stable with few external dependencies
- Focus on business logic

**Examples**:
```ruby
# spec/models/company_spec.rb
RSpec.describe Company, type: :model do
  # Minimal testing for standard validations
  it { is_expected.to validate_presence_of(:name) }
  
  # Concise testing of input/output for custom methods
  describe "#calculate_usage_fee" do
    let(:company) { create(:company) }
    
    context "basic fee calculation" do
      it "returns fee based on number of users" do
        create_list(:user, 5, company: company)
        expect(company.calculate_usage_fee).to eq(5000)
      end
    end
  end
end

# spec/services/price_calculator_spec.rb
RSpec.describe PriceCalculator do
  describe "#calculate" do
    it "calculates price from user count and period" do
      calculator = described_class.new(users: 10, period: :monthly)
      expect(calculator.calculate).to eq(10000)
    end
  end
end

# spec/lib/validators/email_validator_spec.rb
RSpec.describe EmailValidator do
  describe "#validate" do
    it "validates email addresses" do
      validator = described_class.new
      expect(validator.validate("user@example.com")).to be true
      expect(validator.validate("invalid")).to be false
    end
  end
end
```

### Request Spec

**Purpose**: Verify application behavior at the HTTP request/response level

**When to use**:
- Simple screen operation verification
- Form submission and redirect confirmation
- Authentication/authorization behavior verification
- API endpoint testing
- Flash message confirmation
- HTTP status code verification

**Characteristics**:
- Fast execution
- Stable in CI environments as no browser is launched
- No JavaScript execution required

**Examples**:
```ruby
# spec/requests/admin/companies_spec.rb
RSpec.describe "Admin::Companies", type: :request do
  describe "GET /admin/companies" do
    it "displays companies list" do
      get admin_companies_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("User Management")
    end
  end

  describe "POST /admin/companies" do
    it "creates a new company" do
      post admin_companies_path, params: { company: { name: "New Company" } }
      expect(response).to redirect_to(admin_company_path(Company.last))
      follow_redirect!
      expect(response.body).to include("Company created successfully")
    end
  end
end
```

### System Spec

**Purpose**: End-to-end verification of user operations through a browser

**When to use**:
- Complex operations requiring custom JavaScript
- Dynamic UI element operations (custom modals, dynamic dropdowns, tab switching, etc.)
- Asynchronous processing using Ajax/Turbo
- Interactions like drag & drop
- Real-time validation
- Complex flows spanning multiple steps

**When System Spec is unnecessary**:
- Browser standard delete confirmation dialogs (`confirm`)
- Simple delete operations via Turbo
- Standard form submissions
- Static content display verification

**Characteristics**:
- Uses actual browser (Selenium)
- JavaScript execution possible
- Slow execution speed
- Prone to timing issues in CI environments

**Examples**:
```ruby
# spec/system/admin/products_spec.rb
RSpec.describe "Admin Products", type: :system do
  describe "Product sorting", js: true do
    it "can change order via drag & drop" do
      visit admin_products_path
      
      # Drag & drop operation
      source = find("#product_#{product1.id}")
      target = find("#product_#{product2.id}")
      source.drag_to(target)
      
      # Wait for Ajax completion
      expect(page).to have_content("Order updated successfully")
    end
  end

  describe "Dynamic forms", js: true do
    it "updates subcategories when category is selected" do
      visit new_admin_product_path
      
      select "Electronics", from: "Category"
      # Wait for subcategories to update via Ajax
      expect(page).to have_select("Subcategory", options: ["TV", "Refrigerator"])
    end
  end
end
```

## Best Practices

### 1. Test Level Selection Priority

1. **Unit Test**: Test business logic at the smallest unit
2. **Request Spec**: Use Request Spec for HTTP layer behavior
3. **System Spec**: Use only when JavaScript is essential

### 2. Unit Test Principles

- Trust Rails standard features and avoid over-testing
- Clearly test input/output of custom methods
- Include boundary value testing for complex business logic
- Minimize database access (appropriate use of FactoryBot)

### 3. System Spec Considerations

- Always explicitly specify `js: true` option
- Include appropriate wait processing (utilize `wait` option)
- Write robust code considering CI environment execution

### 4. Test Maintainability

- Unit tests easily follow business logic changes
- Request Specs are fast and stable, suitable for basic feature regression testing
- Limit System Specs to important user flows, keeping the number minimal

### 5. Performance Considerations

- Unit test execution time: ~0.01 seconds/test
- Request Spec execution time: ~0.1 seconds/test
- System Spec execution time: 1-5 seconds/test
- Be mindful of total execution time in CI environments

## Migration Guidelines

Review existing System Specs and consider migration to Request Specs based on these criteria:

1. Not using JavaScript (`js: true` not required)
2. Only simple form submission and redirect confirmation
3. Only static content display verification
