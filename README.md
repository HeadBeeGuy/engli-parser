Englipedia parser
===

This is a collection of some Ruby scripts that I'm using to pull data from the Englipedia archive in preparation for importing it to ALTopedia's database.

Englipedia's HTML is irregular, to say the least (try looking in the raw_html folder), so I'm using html2text to clear all of the tags out and then running Ruby regular expressions on the result to try and pull out information. There's certainly lots of room for improvement!

At the time of initial commit, I'm able to extract most of an activity's useful information. Some activities have a "grammar point" section, which I haven't gotten around to extracting yet.

General plans for the future, in rough order:

- Decide if I want to store extracted files in json
- Add more sample activities to further refine regular expressions
- Add in spidering from the Englipedia archive directly
- Integrate this code into ALTopedia so that it will populate an Activity object with information generated from these scripts
- Automatically download and attach the accompanying files into the Activity object

This isn't a gem, but if you download the whole thing and have the nokogiri and html2text gems, you can run the scripts directly with the "ruby" command. I don't know if this will be useful to anyone other than myself, but I'm gonna plop it on Github so I can work on it on my laptop or my desktop.