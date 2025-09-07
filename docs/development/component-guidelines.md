# Component Design Guidelines

## Core Principles

This project adopts component-based UI design using ViewComponent. These guidelines provide direction for creating consistent and reusable components.

## Component Concepts

A component is a reusable element that functions independently within the UI. It has the following characteristics:

- **Independence**: Functions standalone without dependencies on other code
- **Reusability**: Can be used in various contexts
- **Clear Responsibility**: Has a single role or function
- **Encapsulation**: Hides internal implementation details

## Component Creation Guidelines

### Naming Conventions

- Use clear and specific names for components (e.g., `UserCard`, `NavigationMenu`)
- Names should represent functionality or role, making their purpose immediately understandable
- Use CamelCase for compound nouns consistently
- Use snake_case for component filenames and directory names

### Component Granularity

- Components follow the single responsibility principle
- Design at the smallest reusable unit
- Consider splitting components larger than 300 lines
- Complex components should be composed of smaller components

### Component Hierarchy

Components are classified into the following categories:

1. **Atomic Components**: Basic elements at the smallest unit (buttons, input fields, labels, etc.)
2. **Molecular Components**: Functional units combining atomic components (form groups, cards, etc.)
3. **Organism Components**: Complex UI combining multiple molecules and atoms (navigation, form sections, etc.)
4. **Templates**: Components that form page layouts
5. **Pages**: Final user-facing screens

### Component Creation Command

Create components using the following command:

```bash
bin/rails g view_component ComponentName [attributes]
```

Example:
```bash
bin/rails g view_component UserCard name email avatar_url
```

This command generates the following files:

- `app/frontend/components/user_card/component.rb`: Component class
- `app/frontend/components/user_card/component.html.erb`: Component template
- `app/frontend/components/user_card/preview.rb`: Component preview
- `spec/frontend/components/user_card_spec.rb`: Unit test
- `spec/system/frontend/components/user_card_spec.rb`: System test

### Component Structure

A standard component consists of the following elements:

1. **Class Definition**: Defines component logic and properties
2. **Template**: Defines component HTML structure
3. **Preview**: Defines component display in development environment

#### Component Class Example

```ruby
# app/frontend/components/user_card/component.rb
class UserCard::Component < ApplicationViewComponent
  # Collection support configuration
  with_collection_parameter :user
  
  # Property definitions
  option :name
  option :email
  option :avatar_url, default: nil
  option :active, default: true
  
  # Helper methods
  def status_classes
    if active
      "bg-green-100 border-green-500 text-green-800"
    else
      "bg-gray-100 border-gray-300 text-gray-600"
    end
  end
  
  # Event handlers and additional logic
  def render?
    name.present?
  end
end
```

#### Template Example

```erb
<!-- app/frontend/components/user_card/component.html.erb -->
<div class="user-card <%= status_classes %> p-4 rounded-md border-l-4 mb-4">
  <div class="flex items-center space-x-4">
    <% if avatar_url.present? %>
      <img src="<%= avatar_url %>" alt="<%= name %>" class="w-12 h-12 rounded-full">
    <% else %>
      <div class="w-12 h-12 bg-gray-300 rounded-full flex items-center justify-center">
        <span class="text-gray-600 font-bold"><%= name.first %></span>
      </div>
    <% end %>
    
    <div>
      <h3 class="font-bold text-lg"><%= name %></h3>
      <p class="text-gray-600"><%= email %></p>
    </div>
  </div>
  
  <% if content.present? %>
    <div class="mt-3">
      <%= content %>
    </div>
  <% end %>
</div>
```

#### Preview Example

```ruby
# app/frontend/components/user_card/preview.rb
class UserCard::Preview < ApplicationViewComponentPreview
  # Default preview display
  def default
    render UserCard::Component.new(
      name: "John Doe",
      email: "john@example.com"
    )
  end
  
  # Preview with avatar
  def with_avatar
    render UserCard::Component.new(
      name: "Jane Smith",
      email: "jane@example.com",
      avatar_url: "https://via.placeholder.com/150"
    ) do
      "Additional information displayed here"
    end
  end
  
  # Inactive state preview
  def inactive
    render UserCard::Component.new(
      name: "Bob Johnson",
      email: "bob@example.com",
      active: false
    )
  end
end
```

## Component Design Best Practices

### Property Design

- Define properties explicitly
- Clearly distinguish between required and optional properties
- Set default values appropriately
- Apply constraints to property types and ranges

### Styling

- Contain component-specific styles within the component
- Use Tailwind utility classes as the foundation
- Extract complex styles into component-specific classes
- Support responsive design

### Testing Strategy

- Create unit tests and system tests for each component
- Test property boundary values and edge cases
- Test rendering conditions and show/hide logic
- Simulate user interactions for interactive components

### Component Reusability

- Similar components should inherit from a common base component
- Utilize slots and yields to provide flexible internal structure
- Design component variations explicitly
- Use blocks or procs for advanced customization

### Component Documentation

- Add appropriate comments to each component
- Previews should cover various use cases
- Provide explanations for complex properties or options
- Provide usage examples

## Project-Specific Component Design

### Basic UI Components

Prepare the following essential components for web applications:

1. **Button**: General-purpose button component
2. **Card**: Information display card component
3. **Form**: Form-related component group
4. **Navigation**: Navigation-related components
5. **Modal**: Modal dialog component
6. **Alert**: Notification and alert components

### Data Flow Design

Data flow between components follows these patterns:

1. **Top-down data flow via properties**: Parent-to-child data passing
2. **Bottom-up notification via events**: Child-to-parent change notifications
3. **State management via Stimulus controllers**: Complex state management and UI logic
4. **Server-side updates via Turbo Stream**: Asynchronous data updates and UI reflection

### Interactive Components

Integrate Stimulus.js for components involving user interaction:

```ruby
# app/frontend/components/interactive_form/component.rb
class InteractiveForm::Component < ApplicationViewComponent
  option :form_data
  option :current_step, default: 1
  
  def stimulus_controller
    "interactive-form"
  end
  
  def stimulus_values
    {
      current_step: current_step,
      total_steps: form_data.steps.count
    }
  end
end
```

```erb
<!-- app/frontend/components/interactive_form/component.html.erb -->
<div data-controller="<%= stimulus_controller %>"
     data-<%= stimulus_controller %>-current-step-value="<%= current_step %>"
     data-<%= stimulus_controller %>-total-steps-value="<%= form_data.steps.count %>">
  <!-- Component content -->
</div>
```

## Building and Utilizing Component Library

### Component Catalog

Build a component catalog using Lookbook:

- Accessible at `/dev/lookbook` in development environment
- Display variations of each component
- Verify component behavior through property changes
- Display documentation and usage examples

### Component Discoverability

- Use consistent naming conventions for easy searching
- Group related components in directories
- Categorize by purpose
- Distinguish between common and specific-purpose components

## Performance Optimization

- Utilize rendering cache for large components
- Design to avoid unnecessary re-rendering
- Perform data fetching logic efficiently
- Optimize collection rendering

```ruby
# Example utilizing cache
class UserGallery::Component < ApplicationViewComponent
  with_collection_parameter :user
  
  def cache_key
    "user_card/#{user.id}-#{user.updated_at.to_i}"
  end
  
  def before_render
    # Preload necessary data
  end
end
```

## Accessibility Support

- All components comply with WCAG guidelines
- Support keyboard navigation
- Use appropriate ARIA roles and attributes
- Provide text alternatives for screen readers
- Ensure color contrast ratios

---

Following these guidelines enables building a consistent and maintainable component library, streamlining UI development for this project.