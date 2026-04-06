script "revAboutCardBehavior"
on preOpenStack
   lock screen
   put "0.9.8" && "| Build" && the buildNumber into field "version"
   set the loc of this stack to the screenLoc
   unlock screen
end preOpenStack
