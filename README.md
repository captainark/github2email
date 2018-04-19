# Github2eMail

## What is it ?

Github2eMail is a bash script that parses the GitHub API for projects you've starred and adds them to your rss2email configuration.

The script will also delete projects it has added to your rss2email configuration if you're not starring them on GitHub anymore.

## Dependencies

- [curl](https://github.com/curl/curl)
- [rss2email](https://github.com/wking/rss2email)
- [jq](https://github.com/stedolan/jq)

## How do I use it ?

You need to have installed and configured rss2email first.

Clone this repo.

Edit the `config` file and modify the `UserName` variable to your GitHub username.

Run the script.

You're done !

You can also run the script periodically from cron if you want.
