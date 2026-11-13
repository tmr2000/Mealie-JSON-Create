# Project instructions

This project is Mealie JSON Create, a Windows PowerShell WPF recipe-to-Mealie JSON application.

## Versions and release notes

- Maintain CHANGELOG.md whenever making a user-visible change. Add concise notes under Unreleased while work is in progress.
- For a new local release, choose a version using the README.md policy, update AppVersion in Recipe.Core.ps1, and move the completed Unreleased notes into a dated section for that version. Leave an Unreleased heading for future work.
- Never overwrite the contents of an already published release; publish a new version instead. Correct factual documentation errors transparently.
- Keep the app footer, build metadata, changelog heading and EXE filename consistent with AppVersion. Do not introduce a second version constant.
- All built EXEs must include the version in the filename: MealieJsonCreate-MAJOR.MINOR.PATCH.exe. Keep build outputs in dist/ and out of Git; distribute EXEs through GitHub Releases.
- Keep Windows PowerShell 5.1 compatibility unless a required feature justifies changing it.
