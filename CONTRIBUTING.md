# Contributing to Dawny

Thanks for your interest in Dawny. This is a small, opinionated, single-developer
project, but contributions are welcome — within the constraints below.

## License of Contributions (important)

Dawny is licensed under the [MIT License](LICENSE). This affects how contributions
are handled.

By submitting a pull request, an issue with code suggestions, or any other
contribution to this repository, you agree that:

1. **Inbound = Outbound.** Your contribution is licensed to the project under the
   exact same terms as the rest of the project — currently the MIT License. You
   cannot submit code that is incompatible with that license (for example,
   GPL-licensed code).

2. **You have the right to contribute.** You confirm that the contribution is
   your own original work, or that you have the rights to submit it under these
   terms. If your employer has rights to your work, you confirm you have
   permission to contribute.

If you do not agree with these terms, please do not submit code. Bug reports and
feature discussions in issues are still welcome.

## What kind of contributions fit Dawny

Dawny is deliberately small. The "Zero Overdue" philosophy and the two-list
model (Backlog + Daily Focus) are non-negotiable. Before opening a large PR,
please open an issue to discuss whether the change fits the product direction.

Good fits:

- Bug fixes and crash fixes.
- Localization improvements (the app ships in 9 languages).
- Accessibility (Dynamic Type, VoiceOver, Reduce Motion).
- Test coverage, especially around the 3 AM reset and EventKit sync edges.
- Performance improvements.

Probably not a fit:

- Recurring tasks, subtasks, tags, due dates, multiple projects.
- Cross-platform code (Android, web, watchOS unless specifically scoped).
- Third-party dependencies. Dawny intentionally has none.

## How to contribute

1. Fork the repo and create a feature branch.
2. Make your change. Follow the existing code style. Run the tests.
3. Open a PR against `main` with a clear description of what changed and why.
4. Be patient — this is a side project.

## Development setup

Requirements:

- Xcode 26.2 or later.
- macOS able to run Xcode 26.2.
- An iPhone or simulator running iOS 26.2 or later.
- An Apple Developer account is needed only for device deploys, not for
  building or running tests on the simulator.

No package manager setup is needed. Dawny has zero third-party dependencies.

## Reporting security issues

Do not open public issues for security reports. Email **info@dawnyapp.com** with
details. I will respond as fast as a single developer can.
