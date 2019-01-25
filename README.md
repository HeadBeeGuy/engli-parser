Englipedia parser
===

This is a collection of some Ruby scripts that I'm using to pull data from the Englipedia archive in preparation for importing it to ALTopedia's database.

Englipedia's HTML is irregular, to say the least (try looking in the raw_html folder), so I'm using html2text to clear all of the tags out and then running Ruby regular expressions on the result to try and pull out information. There's certainly lots of room for improvement!

At the time of initial commit, I'm able to extract most of an activity's useful information. Some activities have a "grammar point" section, which I haven't gotten around to extracting yet.

I've been dragging my feet on this for a while, so I'm going to try and follow these steps to get something working soon:

- Define code that identifies "pages of activity pages" - things like the page that lists all grammar points - and then assembles them into an list.
- Take that list and add them to a list of "pages of activities" which are pages that can be directly read as activity data.
- Run the page analysis on each of those pages and save the result as either JSON or yaml. Maybe one file for activity is better.
- Add an "Englipedia activity" model to ALTopedia. I imagine I'll need to populate this as part of a database migration.
- Allow ALTopedia admins to look at Englipedia activities and then use them to populate a new ALTopedia activity object.

This isn't a gem, but if you download the whole thing and have the nokogiri and html2text gems, you can run the scripts directly with the "ruby" command. I don't know if this will be useful to anyone other than myself, but I'm gonna plop it on Github so I can work on it on my laptop or my desktop.


