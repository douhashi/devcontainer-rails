# Ruby on Rails Coding Standards

## Core Principles

This project establishes coding standards for Ruby on Rails-based web application development to ensure code consistency, readability, and maintainability. These standards promote collaboration among developers and maintain a high-quality codebase.

All developers are required to follow these standards to maintain project quality and promote collaboration among team members.

## General Guidelines

- Follow the DRY (Don't Repeat Yourself) principle
- Design code following SOLID principles
- Write self-explanatory code (don't rely too heavily on comments)
- Add appropriate comments for complex logic
- Methods should follow the single responsibility principle and perform only one task
- Naming should be clear and reflect its purpose
- Follow Rails conventions (Convention over Configuration)
- Use ViewComponent for view componentization

## Rails Generator Usage

When creating new files, utilize Rails' standard Generators. This automatically generates appropriate file structures and code that align with Rails conventions.

### Basic Generator Commands

#### Controller Generation
```bash
# Basic controller generation
bin/rails g controller Products index show

# API-only controller
bin/rails g controller api/v1/products --api

# With skip options
bin/rails g controller Products --skip-routes --skip-helper
```

#### Model Generation
```bash
# Basic model generation
bin/rails g model Product name:string price:decimal inventory:integer

# Model with associations
bin/rails g model Comment content:text user:references product:references

# With indexes
bin/rails g model Product name:string:index sku:string:uniq
```

#### Migration Generation
```bash
# Add column
bin/rails g migration AddStatusToProducts status:string

# Remove column
bin/rails g migration RemovePriceFromProducts price:decimal

# Add index
bin/rails g migration AddIndexToProductsSku

# Join table
bin/rails g migration CreateJoinTableProductsCategories products categories
```

#### ViewComponent Generation
```bash
# Basic component generation
bin/rails g view_component Card
```

#### Other Useful Generators
```bash
# Stimulus controller
bin/rails g stimulus dropdown

# Job
bin/rails g job SendNewsletterJob

# Mailer
bin/rails g mailer UserMailer welcome

# Channel (Action Cable)
bin/rails g channel Notification
```

### Generator Usage Guidelines

1. **Follow Naming Conventions**
   - Generators automatically create filenames following Rails naming conventions
   - Pay attention to singular/plural usage (Models are singular, Controllers are plural)

2. **Post-Generation Review**
   - Always review generated files after running generators and adjust to match project conventions
   - Remove unnecessary comments and code

3. **Rollback**
   - If generated incorrectly, use `bin/rails destroy` command to undo
   - Example: `bin/rails destroy controller Products`

## Ruby Coding Standards

### Style

- Follow [Rubocop Rails Omakase](https://github.com/rails/rubocop-rails-omakase) ruleset
- Use 2 spaces for indentation
- Maximum line length is 120 characters (80 characters recommended for comments)
- Leave one blank line between method definitions
- Group methods within classes logically
- Add blank lines for class, module, and method definitions
- Minimize use of private methods and instance variables

### Naming Conventions

- Variables and methods: snake_case (`get_user_data`)
- Constants: uppercase snake_case (`MAX_RETRY_COUNT`)
- Classes and modules: PascalCase (`UserAccount`)
- Filenames: snake_case (`user_account.rb`)
- Boolean-returning methods: end with question mark (`valid?`, `authenticated?`)
- Destructive methods: end with exclamation mark (`save!`, `update!`)

### Ruby Best Practices

```ruby
# Use guard clauses for early returns
def process_user(user)
  return unless user.active?
  return if user.suspended?
  
  # Main processing
  user.process_data
end

# Use symbol-to-proc for method calls
users.map(&:name)

# Use string interpolation
"Hello, #{user.name}!"

# Hash shorthand notation (Ruby 3.1+)
{ name:, email:, age: }

# Safe navigation operator
user&.profile&.avatar_url
```

### Active Record Best Practices

```ruby
# Define scopes
class User < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :with_profile, -> { includes(:profile) }
  
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :age, numericality: { greater_than_or_equal_to: 18 }
  
  # Use callbacks cautiously
  before_save :normalize_email, if: :email_changed?
  
  private
  
  def normalize_email
    self.email = email.downcase.strip
  end
end

# Prevent N+1 queries
users = User.includes(:posts, :profile).where(active: true)

# Use find_each for processing large datasets
User.find_each(batch_size: 1000) do |user|
  user.send_newsletter
end
```

## Rails-Specific Guidelines

### Rails Best Practices

- Follow the Fat Model, Skinny Controller principle
- Extract complex business logic into service objects
- Place validations in appropriate models
- Use `includes` and `joins` actively to avoid N+1 query problems
- Split large controllers using Concerns
- Utilize directories like `app/services` and `app/queries`
- Follow standard Rails naming conventions and structure

### ActiveRecord Usage

- Naming convention: table names are plural, model names are singular
- Define associations (`has_many`, `belongs_to`, etc.) in logical order
- Use scopes to encapsulate query logic
- Avoid using `default_scope`
- Extract complex queries into named scopes or query objects

### MVC Architecture

#### Model

```ruby
# Fat Model, Skinny Controller principle
class Survey < ApplicationRecord
  belongs_to :user
  has_many :responses, dependent: :destroy
  
  # Business logic belongs in models
  def calculate_reform_points
    ReformPointCalculator.new(self).calculate
  end
  
  # Query methods
  def self.recent(days = 7)
    where('created_at >= ?', days.days.ago)
  end
end
```

#### Controller

```ruby
class SurveysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_survey, only: [:show, :edit, :update, :destroy]
  
  def index
    @surveys = current_user.surveys.recent.page(params[:page])
  end
  
  def create
    @survey = current_user.surveys.build(survey_params)
    
    if @survey.save
      redirect_to @survey, notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_survey
    @survey = current_user.surveys.find(params[:id])
  end
  
  def survey_params
    params.require(:survey).permit(:name, :dog_name, :breed_id)
  end
end
```

#### View

```erb
<%# app/views/surveys/index.html.erb %>
<%= render 'shared/page_header', title: t('.title') %>

<div class="surveys-grid">
  <%= render partial: 'survey', collection: @surveys %>
</div>

<%= paginate @surveys %>
```

### Service Objects

Extract complex business logic into service objects:

```ruby
# app/services/survey_processor.rb
class SurveyProcessor
  include ActiveModel::Model
  
  attr_accessor :survey, :user
  
  validates :survey, :user, presence: true
  
  def process
    return false unless valid?
    
    ActiveRecord::Base.transaction do
      create_survey_record
      calculate_points
      send_notification
    end
    
    true
  rescue StandardError => e
    errors.add(:base, e.message)
    false
  end
  
  private
  
  def create_survey_record
    @record = Survey.create!(survey_attributes)
  end
  
  def calculate_points
    ReformPointCalculator.new(@record).calculate
  end
  
  def send_notification
    SurveyMailer.completed(@record).deliver_later
  end
end
```

### Form Objects

```ruby
# app/forms/survey_form.rb
class SurveyForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :name, :string
  attribute :email, :string
  attribute :dog_name, :string
  attribute :breed_id, :integer
  
  validates :name, :email, :dog_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  def save
    return false unless valid?
    
    Survey.create!(attributes)
  end
end
```

### ViewComponent

- Component names should clearly represent their functionality
- One component should have only one responsibility
- Make components as reusable as possible
- Split large components into smaller components
- Keep component styling contained within the component
- Provide previews for all components
- Set appropriate default values for parameters
- Always define parameter types
- Components must be self-contained

```ruby
# app/components/button_component.rb
class ButtonComponent < ViewComponent::Base
  VARIANTS = {
    primary: "bg-blue-500 text-white hover:bg-blue-600",
    secondary: "bg-gray-200 text-gray-800 hover:bg-gray-300",
    danger: "bg-red-500 text-white hover:bg-red-600"
  }.freeze
  
  def initialize(text:, variant: :primary, **options)
    @text = text
    @variant = variant
    @options = options
  end
  
  private
  
  attr_reader :text, :variant, :options
  
  def css_classes
    [
      "px-4 py-2 rounded font-medium transition-colors",
      VARIANTS[variant],
      options[:class]
    ].compact.join(" ")
  end
end
```

#### Detailed Component Structure Example

```ruby
# app/frontend/components/sample_button/component.rb
module SampleButton
  class Component < ApplicationViewComponent
    attr_reader :label, :variant, :disabled
    
    # Define parameters explicitly
    def initialize(label:, variant: :primary, disabled: false)
      @label = label
      @variant = variant
      @disabled = disabled
    end
    
    # View helpers
    def button_classes
      base_classes = "rounded-md px-4 py-2 font-medium"
      variant_classes = variant_class_map[@variant.to_sym] || variant_class_map[:primary]
      "#{base_classes} #{variant_classes} #{disabled_classes}"
    end
    
    private
    
    def variant_class_map
      {
        primary: "bg-blue-500 text-white hover:bg-blue-600",
        secondary: "bg-gray-200 text-gray-800 hover:bg-gray-300",
        danger: "bg-red-500 text-white hover:bg-red-600"
      }
    end
    
    def disabled_classes
      disabled ? "opacity-50 cursor-not-allowed" : ""
    end
  end
end
```

- Detailed ViewComponent guidelines are documented in @docs/development/component-guidelines.md

## JavaScript (Stimulus) Coding Standards

### Stimulus Controllers

- Controller names use kebab-case (`questionnaire-form`)
- Action names should be clear and indicate their purpose (`submitForm`)
- Data attributes use kebab-case (`data-controller="form"`)
- Stimulus controllers follow the single responsibility principle
- Avoid using global variables
- Add and remove event listeners properly within Stimulus lifecycle methods
- Extract complex logic into separate service classes

```javascript
// app/frontend/controllers/form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]
  static values = { url: String }
  
  connect() {
    this.validateForm()
  }
  
  validateForm() {
    const isValid = this.inputTargets.every(input => input.value.trim() !== "")
    this.submitTarget.disabled = !isValid
  }
  
  async submit(event) {
    event.preventDefault()
    
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfToken,
          "Content-Type": "application/json"
        },
        body: JSON.stringify(this.formData)
      })
      
      if (response.ok) {
        Turbo.visit(response.headers.get("Location"))
      }
    } catch (error) {
      console.error("Form submission failed:", error)
    }
  }
  
  get formData() {
    return Object.fromEntries(new FormData(this.element))
  }
  
  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']").content
  }
}
```

#### Detailed Stimulus Controller Example

```javascript
// app/frontend/controllers/questionnaire_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submitButton", "progressBar"]
  static values = { 
    currentStep: Number,
    totalSteps: Number 
  }
  
  connect() {
    this.updateProgressBar()
  }
  
  nextStep(event) {
    event.preventDefault()
    if (this.validateCurrentStep()) {
      this.currentStepValue++
      this.updateProgressBar()
      this.showCurrentStep()
    }
  }
  
  validateCurrentStep() {
    // Validation logic
    return true
  }
  
  updateProgressBar() {
    const progress = (this.currentStepValue / this.totalStepValue) * 100
    this.progressBarTarget.style.width = `${progress}%`
  }
  
  showCurrentStep() {
    // Step display logic
  }
}
```

## CSS (Tailwind)

- Prefer class selectors over tag selectors
- Use consistent design tokens across components
- Minimize custom CSS classes, use Tailwind utilities whenever possible
- Use Tailwind breakpoints for responsive design (`sm:`, `md:`, `lg:`, etc.)
- Extract complex styles using the `@apply` directive
- Use Tailwind configuration values for consistent spacing and sizing
- Use Tailwind color palette, avoid hardcoded color values

## Testing

Detailed testing guidelines and strategies are documented in @docs/development/testing-strategy.md

## Internationalization (I18n)

### Usage in Views

```erb
<%# Use translation keys %>
<h1><%= t('.title') %></h1>
<p><%= t('surveys.instructions') %></p>

<%# Translations with variables %>
<%= t('.welcome', name: current_user.name) %>

<%# Model attribute translations %>
<%= f.label :dog_name %>
```

### Locale Files

```yaml
# config/locales/en.yml
en:
  activerecord:
    models:
      survey: Survey
      user: User
    attributes:
      survey:
        name: Name
        dog_name: Dog's name
        breed: Breed
  
  surveys:
    index:
      title: Survey List
    new:
      title: New Survey
    create:
      success: Survey created successfully
```

## Security

### Strong Parameters

```ruby
# Permit only necessary parameters
def survey_params
  params.require(:survey).permit(:name, :email, :dog_name, :breed_id, images: [])
end
```

### Authentication and Authorization

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  
  private
  
  def not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end
end
```

### CSRF Protection

```erb
<%# CSRF tokens are automatically included in forms %>
<%= form_with model: @survey do |f| %>
  <%# ... %>
<% end %>
```

## Performance Optimization

### Database Queries

```ruby
# Prevent N+1 queries
@surveys = Survey.includes(:user, :responses).recent

# Select only necessary columns
User.select(:id, :name, :email).active

# Use counter cache
class Survey < ApplicationRecord
  belongs_to :user, counter_cache: true
end
```

### View Optimization

```erb
<%# Fragment caching %>
<% cache @survey do %>
  <%= render @survey %>
<% end %>

<%# Collection caching %>
<%= render partial: 'survey', collection: @surveys, cached: true %>
```

## Code Review

- PRs require at least one reviewer
- Reviews should check for:
  - Compliance with coding standards
  - Test adequacy and coverage
  - Performance considerations
  - Security vulnerabilities
  - Documentation updates
- Feedback should be constructive and specific
- When fixes are needed, provide reasoning and improvement suggestions

## Code Review Checklist

- [ ] Complies with Rubocop rules
- [ ] Tests are adequately written
- [ ] No N+1 queries present
- [ ] Strong Parameters properly configured
- [ ] I18n properly used
- [ ] Security considerations addressed
- [ ] No performance issues

## Continuous Integration

- Run automated tests on every push
- Perform the following checks before merging:
  - Unit and system tests pass
  - Code coverage verification
  - Static analysis with Rubocop
  - Security scans
  - Performance metrics verification

## Documentation

- Add documentation comments for public APIs and custom classes
- Keep README up-to-date with current information
- Add comments explaining reasoning and behavior for complex logic or algorithms
- Document important decisions and architectural choices

---

Following these standards enables development of maintainable, secure, and efficient Rails applications. These standards will be updated as needed and evolve with the project's growth.