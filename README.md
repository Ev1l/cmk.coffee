# ByDesign.coffee

This script allows you to manipulate ByDesign accounts via Hubot. You can activate, deactivate, and change the password of any account via the hubot.

See [`src/bydesign.coffee`](src/bydesign.coffee) for full documentation.

## Sample Interaction

```
user1>> bydesign deactivate user1
hubot>> Username has been deactivated

user1>> bydesign activate user1
hubot>> Username has been activated

user1>> bydesign reset user1 password1234
hubot>> Passwords have been updated for (1) users
```
