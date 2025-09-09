# frozen_string_literal: true

module Button
  class Preview < ApplicationViewComponentPreview
    # Default button
    # ----------------
    # Basic button with default settings
    def default
      render(Button::Component.new(text: "Click me"))
    end

    # Button variants
    # ---------------
    # All available button variants
    def variants
      render_with_template(locals: {})
    end

    # Button sizes
    # ------------
    # All available button sizes
    def sizes
      render_with_template(locals: {})
    end

    # Loading state
    # -------------
    # Button with loading spinner
    def loading
      render(Button::Component.new(text: "Processing...", loading: true))
    end

    # Disabled state
    # --------------
    # Disabled button that cannot be clicked
    def disabled
      render(Button::Component.new(text: "Disabled", disabled: true))
    end

    # With custom data attributes
    # ---------------------------
    # Button with Stimulus controller attached
    def with_stimulus
      render(Button::Component.new(
        text: "Click to trigger",
        data: {
          controller: "example",
          action: "click->example#handleClick",
          example_value: "test-123"
        }
      ))
    end

    # Link button
    # -----------
    # Button rendered as a link
    def as_link
      render(Button::Component.new(
        text: "Go to dashboard",
        href: "/dashboard",
        variant: :primary
      ))
    end

    # Button with icon
    # ----------------
    # Using block content to add custom icon
    def with_icon
      render_with_template(locals: {})
    end

    # All combinations
    # ----------------
    # Grid showing all variant and size combinations
    def all_combinations
      render_with_template(locals: {})
    end

    # Interactive playground
    # ----------------------
    # Customize all button properties
    # @param text text "Button text"
    # @param variant select [primary, secondary, danger, ghost] "Button variant"
    # @param size select [sm, md, lg] "Button size"
    # @param loading toggle "Show loading spinner"
    # @param disabled toggle "Disable button"
    def playground(
      text: "Click me",
      variant: "primary",
      size: "md",
      loading: false,
      disabled: false
    )
      render(Button::Component.new(
        text: text,
        variant: variant.to_sym,
        size: size.to_sym,
        loading: loading,
        disabled: disabled
      ))
    end
  end
end
