#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
  exec wish8.4 "$0" ${1+"$@"}

##
## This file implements a drop target that is able to accept any type dropped.
##
## Check Tk version:
package require Tk 8.3-

if {$::tcl_version == "8.3" && ![package vsatisfies $::tcl_patchLevel 8.3.3]} {
    tk_messageBox -type ok -icon error \
        -message "  =====> TkDND requires at least tk8.3.3! <====="
    exit 1
}

## Make sure that we can find the tkdnd package even if the user has not yet
## installed the package.
if {[catch {package require tkdnd} version]} {
  set DIR [file dirname [file dirname [file normalize [info script]]]]
  source $DIR/library/tkdnd.tcl
  foreach dll [glob -type f $DIR/*tkdnd*[info sharedlibextension]] {
    tkdnd::initialise $DIR/library ../[file tail $dll] tkdnd
  }
  set package_info "Found tkdnd package version (unknown)\n\
                  \nPackage loading info:\n\n$dll"
} else {
  set package_info "Found tkdnd package version $version\n\
                  \nPackage loading info:\n\n[package ifneeded tkdnd $version]"

}

## Place a listbox. This will be our drop target, which will also display the
## types supported by the drag source...
listbox .typeList -height 20 -width 50
## A text widget to display the dropped data...
text .data -height 20 -width 60
.data insert end $package_info
text .position -height 5 -width 50
button .exit -text {  Exit  } -command exit

grid .typeList .data - -sticky snew -padx 2 -pady 2
grid columnconfigure . 1 -weight 1
grid columnconfigure . 2 -weight 1
grid .position - .exit -sticky snew -padx 2 -pady 2

proc FillTypeListbox {listbox types type codes code actions action mods btns} {
    $listbox delete 0 end
    $listbox insert end {}
    $listbox insert end {        --- Types ---}
    $listbox itemconfigure end -foreground white -background red
    foreach t $types c $codes {
        $listbox insert end "$t ($c)"
    }
    $listbox insert end " * Current Type: \"$type\" ($code)"
    $listbox itemconfigure end -foreground red -background $::bg
    $listbox insert end " * Cross Platform Type:\
                          \"[tkdnd::platform_independent_type $type]\""
    $listbox itemconfigure end -foreground red -background $::bg

    $listbox insert end {}
    $listbox insert end {        --- Actions ---}
    $listbox itemconfigure end -foreground white -background blue
    eval $listbox insert end $actions
    $listbox insert end " * Current Action: \"$action\"..."
    $listbox itemconfigure end -foreground blue -background $::bg

    $listbox insert end {}
    $listbox insert end " * Modifiers: \"$mods\", Mouse buttons: \"$btns\""
    $listbox itemconfigure end -foreground brown -background $::bg
}
proc FillPosition {text action X Y data} {
  $text configure -state normal
  $text delete 1.0 end
  $text insert end "Position: (x=$X, y=$Y), Action: $action, Data Preview:\n"
  $text insert end \"$data\"
  $text configure -state disabled
  return $action
};# FillPosition
proc FillData {text Data type code} {
    $text configure -state normal
    $text delete 1.0 end
    $text insert end "\n   --- Dropped Data --- (Type = \"$type\" $code)\n\n\n"
    ## Can the text be split as a list?
    switch -glob [tkdnd::platform_independent_type $type] {
      FileGroupDescriptor* {
        foreach item $Data {
          $text insert end "   *  \"$item\"\n"
          if {[file exists $item]} {
            $text insert end "      ->   File exists. Deleting...\n"
            file delete -force $item
          } else {
            $text insert end "      ->   File missing...\n"
          }
        }
      }
      DND_Files {
        foreach item $Data {
          $text insert end "   *  \"$item\"\n"
        }
      }
      DND_Text -
      default {
        $text insert end $Data
      }
    }
    $text configure -state disabled
}

update
set bg [.typeList cget -background]
set abg #8fbc8f

set type *
dnd bindtarget .typeList $type <DragEnter> ".typeList configure -bg $abg
FillTypeListbox .typeList %t %T %c %C %a %A %m %b
FillPosition    .position %A %X %Y %D"
dnd bindtarget .typeList $type <Drag> \
        [dnd bindtarget .typeList $type <DragEnter>]
dnd bindtarget .typeList $type <Drop> \
        ".typeList configure -bg $bg; FillData .data %D %T %C"
dnd bindtarget .typeList $type <DragLeave> \
        ".typeList configure -bg $bg"
raise .

proc show_widget_under_cursor {} {
  puts "Mouse coordinates: [winfo pointerxy .]"
  puts "Widget under cursor: [winfo containing 200 200]"
  after 200 show_widget_under_cursor
};# show_widget_under_cursor
#show_widget_under_cursor
