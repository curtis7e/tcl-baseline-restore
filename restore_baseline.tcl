#
# restore_baseline.tcl
# Run with:  tclsh flash:restore_baseline.tcl
#

proc main {} {
    # 1) Prompt for clock setting
    puts "\nEnter current time in Cisco 'clock set' format"
    puts " (hh:mm:ss day month year), e.g. 15:04:05 22 Apr 2025:"
    flush stdout
    gets stdin current_time

    # 2) Build temp.cfg
    set tempName "flash:temp.cfg"
    set baseName "flash:baseline.cfg"

    # open temp for writing
    if {[catch {set fw [open $tempName w]} err]} {
        puts "ERROR opening $tempName for write: $err"
        return
    }
    # write the clock set line
    puts $fw "clock set $current_time"

    # open baseline for reading
    if {[catch {set fr [open $baseName r]} err2]} {
        puts "ERROR opening $baseName for read: $err2"
        close $fw
        return
    }

    # copy baseline.cfg into temp
    while {[gets $fr line] >= 0} {
        puts $fw $line
    }
    close $fr
    close $fw

    # 3) Replace running-config with temp.cfg
    puts "\nApplying combined config from $tempName ..."
    if {[catch {cli_exec "configure replace $tempName force"} err3]} {
        puts "ERROR on config replace: $err3"
        return
    }

    # 4) Save and cleanup
    puts "\nWriting new startup-config..."
    if {[catch {cli_exec "write memory"} err4]} {
        puts "ERROR saving config: $err4"
        return
    }

    # optional: delete the temp file
    puts "\nCleaning up temporary file..."
    if {[catch {cli_exec "delete /no-prompt $tempName"} err5]} {
        puts "WARNING: couldn't delete temp file: $err5"
    }

    puts "\nAll done!  Clock set, baseline config (with baked-in clock) applied and written."
}

# Kick it off
main
