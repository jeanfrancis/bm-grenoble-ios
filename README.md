#  BM Grenoble

iOS application for the Grenoble Public Library ([Bibliothèques municipales de Grenoble](https://www.bm-grenoble.fr)), displaying a list of your current loans. 

## How it works

The Grenoble Public Library doesn’t offer a public API to check your account status and loans. This app uses a hidden web view instead, programmatically signing in with the user credentials, then extracting the relevant data by parsing the HTML pages.

## Roadmap

### Basic features
- Store credentials in Keychain
- Multiple pages in results
- Placeholder (no loans)
- French/English localization

### Advanced features
- Items cover image
- Local notification for reminders
- Multiple accounts support
- Renew loans

## Bug report

You can report a bug or a missing feature by opening a [GitHub issue](https://github.com/vtourraine/bm-grenoble-ios/issues).

## Contributions

Contributions are welcome. Please fork this repo, commit your changes, then submit a [pull request](https://github.com/vtourraine/bm-grenoble-ios/pulls).

## Credits

This is an independent project by [Vincent Tourraine](https://www.vtourraine.net), not affiliated with the Grenoble Public Library.  

## License

This application is available under the MIT license. See the [LICENSE.md](./LICENSE.md) file for more info.
