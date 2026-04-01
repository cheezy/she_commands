# She Commands

She Doesn't Ask. She Commands.

A women-focused empowerment platform built to elevate mental resilience, physical readiness, and executive clarity.

## Features

- User authentication (registration, login, magic links, password-based login)
- User profiles with display name
- Account settings (profile, email, password management)
- Account deletion with confirmation
- Internationalization (i18n) ready with Gettext
- Dark mode support with daisyUI theming
- Bold black & white design inspired by [shecommands.ca](https://www.shecommands.ca)

## Tech Stack

- Elixir / Phoenix 1.8
- PostgreSQL
- Tailwind CSS v4 + daisyUI
- Phoenix LiveView

## Getting Started

### Prerequisites

- Elixir 1.19+
- PostgreSQL

### Setup

```bash
mix setup          # Install deps, create DB, run migrations
mix phx.server     # Start the server
```

Visit [localhost:4000](http://localhost:4000) from your browser.

## Running Tests

```bash
mix test           # Run all tests
mix test --cover   # Run tests with coverage report
```

## Code Quality

```bash
mix format --check-formatted
mix credo --strict
mix sobelow --config .sobelow-conf
```
