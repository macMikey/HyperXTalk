script "revAboutCardBehavior"
on preOpenStack
   lock screen
   put the version && "| Build" && the buildNumber into field "version"
   set the htmlText of field "Copyright" of me to "<p>&copy; " & word -1 of the long date && "HyperXTalk</p>"
   set the title of this stack to "About HyperXTalk" //&& line 4 of the revLicenseInfo
   set the loc of this stack to the screenLoc
   unlock screen
end preOpenStack
