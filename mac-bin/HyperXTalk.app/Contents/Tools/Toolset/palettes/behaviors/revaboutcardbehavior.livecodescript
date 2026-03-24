script "revAboutCardBehavior"
on preOpenStack
   local tEdition, tPath
   
   lock screen
   
   put the version && "| Build" && the buildNumber into field "version"
   set the blendLevel of field "version" to 40
   
   set the htmlText of field "Copyright" of me to "<p>&copy; " & word -1 of the long date && "HyperXTalk</p>"
   revFontApplySystemStyle the long id of field "Copyright" of me, empty, empty
   
   set the textColor of char 1 to -1 of field "displayData" of me to empty
   --   set the textColor of char 1 to 5 of field "displayData" of me to aboutHiliteColor()
   loadText "about"
   
   set the title of this stack to "About HyperXTalk" && line 4 of the revLicenseInfo
   
   set the textColor of field "version" of me to empty
   
   set the loc of this stack to the screenLoc
   unlock screen
end preOpenStack


on mouseUp
  close this stack
end mouseUp


on loadText pType
   local tFilePath
   set the itemDel to "/"
   switch pType
      case "about"
         put item 1 to -3 of the filename of stack "home" & "/Support/about.txt" into tFilePath
         break
      case "legal"
         put item 1 to -3 of the filename of stack "home" & "/Support/Open Source Licenses.txt" into tFilePath
         break
   end switch
   put textDecode(url ("binfile:" & tFilePath), "utf-8") into field "credits" of me
end loadText

function aboutHiliteColor
   return revEnvironmentEditionProperty("revabout_hilite_color")
end aboutHiliteColor
