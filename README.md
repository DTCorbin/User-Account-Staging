# User-Account-Staging
This is a small script to allow for bulk staging of user accounts.

In order to use it, You create a users.txt file in the format
of **[username];[group1],[group2],[group3]**... it prompts you to provide
a temporary password that would be used one time once the user is
onboarded. You will also have to change the logon shell in order to
use these accounts because they are set to an invalid shell for security
purposes.
