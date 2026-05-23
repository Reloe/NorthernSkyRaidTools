local L = LibStub("AceLocale-3.0"):NewLocale("NorthernSkyRaidTools", "enUS", true, true)

if not L then return end

-- ============================================================================
-- NSUI.lua — Tab names & misc
-- ============================================================================
L["General"] = true
L["Quality of Life"] = true
L["Ready Check"] = true
L["Reminders"] = true
L["Note-Display"] = true
L["Encounter Alerts"] = true
L["Interrupt Display"] = true
L["Assignments"] = true
L["Private Auras"] = true
L["WA Imports"] = true
L["Nicknames"] = true
L["Version Check"] = true
L["Shared Notes"] = true
L["Personal Notes"] = true
L["Sync Nicknames"] = true
L["%s is attempting to sync their nicknames with you."] = true
L["Cancel"] = true
L["Accept"] = true

-- ============================================================================
-- UI/General.lua — Export/Import popups
-- ============================================================================
L["Export Profile"] = true
L["Import Profile"] = true
L["Done"] = true
L["Import"] = true
L["Exporting profile: |cFF00FFFF%s|r"] = true
L["Paste a profile string below and click Import."] = true
L["Invalid import string. Please check and try again."] = true

-- ============================================================================
-- UI/Reminders.lua — Reminder screens
-- ============================================================================
L["Import Reminder String"] = true
L["Import Personal Reminder String"] = true
L["Update"] = true
L["|cFF00FFFFPersonal|r Reminders"] = true
L["|cFF00FFFFShared|r Reminders"] = true
L["Received:"] = true
L["Active Note"] = true
L["No Boss"] = true
L["Normal"] = true
L["Heroic"] = true
L["Mythic"] = true
L["All Bosses"] = true
L["Confirm Deletion"] = true
L["Delete \"%s\"?"] = true
L["Confirm"] = true
L["Copy"] = true
L["Apply"] = true
L["Delete"] = true
L["Unload"] = true
L["Delete All"] = true
L["Confirm Clear All"] = true
L["Delete ALL reminders?"] = true
L["Load"] = true
L["Load & Send"] = true
L["Save"] = true
L["Invite"] = true
L["Arrange"] = true
L["New"] = true
L["|cFF00FFFFReceived|r %ds ago"] = true
L["|cFF00FFFFReceived|r %dm ago"] = true
L["(No Enc)"] = true

-- ============================================================================
-- UI/Options/General.lua
-- ============================================================================
L["Addon Language"] = true
L["Choose the language used by the addon UI. You will have to reload your UI for all changes to take effect. Automatic will take your client language."] = true
L["Automatic"] = true
L["English (enUS)"] = true
L["Korean (koKR)"] = true
L["Russian (ruRU)"] = true
L["Traditional Chinese (zhTW)"] = true
L["General Options"] = true
L["Disable Minimap Button"] = true
L["Hide the minimap button."] = true
L["Global Font"] = true
L["This changes the Font for everything that doesn't have a specific setting for that. Mainly useful for language compatibility."] = true
L["Global Font-Size"] = true
L["Size of the global font"] = true
L["Global Encounter Font-Size"] = true
L["Size of the global Encounter font"] = true
L["Global Font Outline"] = true
L["Font outline flags applied to all addon text."] = true
L["None"] = true
L["Move Text Display"] = true
L["This lets you move the generic text display used for example the ready check module or the assignments on pull."] = true
L["Setup Manager"] = true
L["Default Arrangement"] = true
L["Default"] = true
L["Sorts groups into a default order (tanks - melee - ranged - healer)"] = true
L["Split Groups"] = true
L["Splits the group evenly into 2 groups. It will even out tanks, melee, ranged and healers, as well as trying to balance the groups by class and specs"] = true
L["Split Evens/Odds"] = true
L["Same as the button above but using groups 1/3/5 and 2/4/6."] = true
L["Show Missing Raidbuffs in Raid-Tab"] = true
L["Show a list of missing raidbuffs in your comp in the raid tab. In there you can swap between Mythic and Flex, which will then only consider players up to group 4/6 respectively."] = true
L["TTS Options"] = true
L["TTS Voice"] = true
L["Voice to use for TTS. Most users will only have ~2 different voices. These voices depend on your installed language packs."] = true
L["TTS Volume"] = true
L["Volume of the TTS"] = true
L["TTS Preview"] = true
L["Enter any text to preview TTS\n\nPress 'Enter' to hear the TTS"] = true
L["Enable TTS"] = true
L["Overlap TTS-Sounds"] = true
L["Allow TTS sounds to overlap each other."] = true
L["Exports your currently active profile to a string that can be shared with others."] = true
L["Imports a profile from a string shared by another player. It will be saved as a new profile you can then load."] = true
L["Profile Management"] = true
L["Current Profile: |cFF00FFFF%s|r"] = true
L["New Profile Name"] = true
L["Enter a name and press Enter to create a new profile."] = true
L["Load Profile"] = true
L["Select a profile to load."] = true
L["Copy Profile Into Current"] = true
L["Select a profile to copy its settings into your current profile."] = true
L["Reset Profile"] = true
L["Select a profile to reset to defaults."] = true
L["Delete Profile"] = true
L["Select a profile to delete. Cannot delete the currently active profile if it is the only one."] = true
L["Main Profile"] = true
L["Set the main profile. This profile will automatically be loaded on any new character you log into."] = true
L["Select..."] = true
L["Created and switched to profile '|cFFFFFFFF%s|r'."] = true
L["Loaded profile '|cFFFFFFFF%s|r'."] = true
L["Copied profile '|cFFFFFFFF%s|r' into '|cFFFFFFFF%s|r'."] = true
L["Reset profile '|cFFFFFFFF%s|r'."] = true
L["Deleted profile '|cFFFFFFFF%s|r'."] = true
L["Main profile set to '|cFFFFFFFF%s|r'."] = true

-- ============================================================================
-- UI/Options/Reminders.lua — Spell Settings
-- ============================================================================
L["Spell Settings"] = true
L["TTS"] = true
L["Whether a TTS sound should be played"] = true
L["TTSTimer"] = true
L["At how much remaining Time the TTS should be played"] = true
L["Duration"] = true
L["How long a reminder should be shown for"] = true
L["Countdown"] = true
L["Whether or not you want a countdown for these reminders. 0 = disabled"] = true
L["Announce Duration"] = true
L["When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'SpellName in 10'"] = true
L["SpellName"] = true
L["Display the SpellName if no text is provided"] = true
L["SpellName TTS if empty"] = true
L["This will make it so that the SpellName is still played as TTS even if the text of the reminder remains empty (so even if you have 'SpellName' unticked)."] = true
L["Default Spell Display"] = true
L["Default display type for reminders with a spell ID. Reminders without a spell ID use text unless their display type is set explicitly."] = true

-- UI/Options/Reminders.lua — Text Settings
L["Text Settings"] = true
L["When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'Spread in 10'"] = true

-- UI/Options/Reminders.lua — Raidframe Icon Settings
L["Raidframe Icon Settings"] = true
L["Position"] = true
L["position on the raidframe"] = true
L["x-Offset"] = true
L["y-Offset"] = true
L["Icon-Width"] = true
L["Width of the Icon"] = true
L["Icon-Height"] = true
L["Height of the Icon"] = true
L["Glow-Color"] = true
L["Color of Raidframe Glows"] = true

-- UI/Options/Reminders.lua — Universal Settings
L["Universal Settings"] = true
L["Hide Timer Text"] = true
L["Play Sound instead of TTS"] = true
L["This will play the selected sound for all reminders instead of using TTS as long as the TTS&Sound fields are empty. The time the sound is played at still uses the TTSTimer value. This also means that any setting that converts the spellName into TTS for example also needs to be disabled for this to work."] = true
L["Ignore 'everyone' tags"] = true
L["Ignores All Reminders that use the 'everyone' tag. For example if there are a lot of reminders shared from your raidlead that you don't want to see, you can filter out these 'everyone' reminders while still getting your personal assigned spells."] = true
L["Hide Reminder Treshold"] = true
L["Treshold above which spells will not be hidden if pressed during the reminder. Some long ramp classes have multiple reminders up at the same time and thus don't want them hidden early"] = true
L["Sound"] = true
L["Show ALL Reminders"] = true
L["This will show you ALL reminders from your notes, regardless of whether the tag matches you or not."] = true

-- UI/Options/Reminders.lua — Manage Reminders
L["Manage Reminders"] = true
L["Preview Alerts"] = true
L["Preview Reminders and unlock their anchors to move them around"] = true
L["Use Shared Reminders"] = true
L["Enables reminders set by the raidleader or shared by an assist"] = true
L["Use Personal Reminders"] = true
L["Enables reminders set into your personal reminder"] = true
L["Use MRT Note Reminders"] = true
L["Enables reminders entered into MRT note"] = true
L["Share on Ready Check"] = true
L["Clear Note on Boss-Kill"] = true
L["Automatically clear the Shared & Personal Note on a Boss-Kill."] = true
L["Only Receive Guild Reminders"] = true
L["Only receive Shared-reminders from guild members."] = true
L["Automatically share the current active reminder on ready check if you are the raidleader. If you want to share a note as assist you can do so in the Shared Reminders-list"] = true
L["Test Active Reminder"] = true
L["Runs a test for the currently active reminder. This will only show phase 1 timers. Press again to cancel the test. This button does nothing if you are using TimelineReminders to display Reminders."] = true
L["Import All Reloe Alerts"] = true
L["Automatically import all of Reloe's custom created Alerts for the current tier's bosses. Display settings of these Alerts can be edited."] = true
L["You are displaying notes and/or alerts through Timelinereminders so this preview makes little senses for you as it won't change what you're seeing. Either change your settings in Timelinereminders instead or disable the settings in there."] = true
-- UI/Options/Reminders.lua — Reminder Note Options
L["This tab is purely for Settings to display Reminders as a Note on-screen. They have no effect on how the in-combat alerts work.\nThere are 3 types of displays. The first one shows all reminders, the second one shows only those that will activate for you. And the third shows all text that is not a reminder."] = true
L["All Reminders Note"] = true
L["Unlock All Reminders"] = true
L["Locks/Unlocks the All Reminders Note to be moved around"] = true
L["Show All Reminders Note"] = true
L["Whether you want to show the All Reminders Note on screen permanently"] = true
L["Font-Size of the All Reminders Note"] = true
L["Font of the All Reminders Note"] = true
L["Width"] = true
L["Width of the All Reminders Note"] = true
L["Height"] = true
L["Height of the All Reminders Note"] = true
L["Background-Color"] = true
L["Color of the Background of the All Reminders Note when unlocked"] = true
L["Show Text-Note in All Reminders Note"] = true
L["Display the Text-Note inside the All Reminders Note."] = true
L["Universal Settings - these apply to all 3 Notes"] = true
L["Hide Player-Names in Note"] = true
L["Hides the Player Names for Reminders in the Note."] = true
L["Show Only Spell-Reminders"] = true
L["With this enabled you will only see Spell-Reminders in your notes."] = true
L["Countdown and Hide Timers in Notes"] = true
L["With this enabled, Timers will count down during combat and completed timers will hide."] = true
L["Show Outside of Raid"] = true
L["With this enabled the Notes will still show outside of raid instances."] = true

-- Reminder Note — Personal
L["Personal Reminder-Note"] = true
L["Unlock Pers Reminder"] = true
L["Locks/Unlocks the Personal Reminders Note to be moved around"] = true
L["Show Personal Reminder Note"] = true
L["Whether you want to display the Note for Reminders only relevant to you"] = true
L["Font-Size of the Personal Reminders Note"] = true
L["Font-Size"] = true
L["Font of the Personal Reminders Note"] = true
L["Width of the Personal Reminders Note"] = true
L["Height of the Personal Reminders Note"] = true
L["Color of the Background of the Personal Reminders Note when unlocked"] = true
L["Show Text-Note in Personal Reminders Note"] = true
L["Display the Text-Note inside the Personal Reminders Note."] = true

-- Reminder Note — Text-Note
L["Text-Note"] = true
L["Unlock Text Note"] = true
L["Locks/Unlocks the Text Note to be moved around. This Note shows anything from the reminders that it is not an actual reminder string. So you can put any text in there to be displayed."] = true
L["Show Text Note"] = true
L["Whether you want to display the Text-Note"] = true
L["Font-Size of the Text-Note"] = true
L["Font of the Text-Note"] = true
L["Width of the Text-Note"] = true
L["Height of the Text-Note"] = true
L["Color of the Background of the Text-Note when unlocked"] = true

-- Reminder Note — Timeline
L["Timeline"] = true
L["Open Timeline"] = true
L["Opens the Timeline window (Also opened by the `/ns tl` or `/ns timeline` slash command)"] = true

-- ============================================================================
-- UI/Options/Assignments.lua
-- ============================================================================
L["Show Assignment on Pull"] = true
L["Shows your Assignment on Pull"] = true
L["For the following Boxes only the Settings of the Raidleader matter."] = true
L["Vaelgor & Ezzorak"] = true
L["Gloom Soaks - Mythic Only"] = true
L["Assigns Group 1&2 to soak the first cast, Group 3&4 to soak the second cast. This is overkill as only 7 people are required. Alternatively you can create a custom Assignment through wowutils."] = true
L["Lightblinded Vanguard"] = true
L["Execution Sentence - Mythic Only"] = true
L["Automatically assigns players to Front Left/Right and Back Left/Right. Melee are preferred for Front Left/Right, Ranged for Back Left/Right. Healers are evenly split, if you are more than 4healers than some healers will be told to have a 'Flex Spot'"] = true
L["Chimaerus"] = true
L["Alndust Upheaval - Mythic"] = true
L["Automatically tells Groups 1&2 to soak the first Cast of Alndust Upheaval and Group 3&4 to soak the second cast"] = true
L["Alndust Upheaval - Normal/Heroic"] = true
L["For Normal & Heroic the Addon automatically splits healers & dps in half. Tanks are ignored."] = true

-- ============================================================================
-- UI/Options/QoL.lua
-- ============================================================================
L["Text Display Settings"] = true
L["Preview/Unlock"] = true
L["Preview and Move the Text Display."] = true
L["Font Size for Text Display. The Font itself is controlled by the Global Font found in General Settings."] = true
L["Gateway Useable Display"] = true
L["Whether you want to see a display when you are able to use the gateway."] = true
L["Reset Boss Display"] = true
L["Shows a Text while out of combat when you have the lust debuff to remind you that the boss needs to be reset."] = true
L["Loot Boss Reminder"] = true
L["Shows a Text after killing a Raid-Boss to remind you to loot the boss for your crests."] = true
L["Consumable Notifications\nrequires others to have NSRT"] = true
L["Soulwell"] = true
L["Shows a Text when a Soulwell has been dropped and you have less than 3 Healthstones."] = true
L["Feast"] = true
L["Shows a Text when a Feast has been dropped and your Well Fed buff is missing or has less than 10 minutes left."] = true
L["Cauldron"] = true
L["Shows a Text when a Cauldron has been dropped."] = true
L["Repair"] = true
L["Shows a Text when a Repair Bot/Anvil has been dropped and your durability is less than 90%."] = true
L["Duration Seconds"] = true
L["Show dropped consumable notifications for the selected number of seconds."] = true
L["Other QoL Things"] = true
L["Check Vantus-Rune"] = true
L["Check the Vantus Rune status for all raid members."] = true
L["Auto-Repair"] = true
L["Whether you want to automatically repair your equipment when visiting a vendor (prefers guild repairs)."] = true
L["Auto-Invite on Whisper"] = true
L["Whether you want to automatically invite Guild-Members when they whisper you with 'inv' or 'invite'."] = true

-- ============================================================================
-- UI/Options/ReadyCheck.lua
-- ============================================================================
L["Gear/Misc Checks"] = true
L["Missing/Wrong Item Check"] = true
L["Checks if any slots are empty or have an item with the wrong armor type equipped"] = true
L["Item Level Check"] = true
L["Checks if you have any slot equipped below the minimum item level"] = true
L["Embellishment Check"] = true
L["Checks if you have 2 Embellishments equipped"] = true
L["4pc Check"] = true
L["Checks if you have 4pc of the current raid-tier equipped."] = true
L["Enchant Check"] = true
L["Checks if you have all slots enchanted"] = true
L["Gem Check"] = true
L["Checks if you have all slots gemmed. Checking for the unique epic gem currently only works on an english client."] = true
L["Repair Check"] = true
L["Checks if any piece needs repair"] = true
L["Gateway Control Shard Check"] = true
L["Checks if you have a Gateway Control Shard and whether or not it is located on your actionbars"] = true
L["Gateway Control Shard Check"] = true
L["Display Group Number"] = true
L["Displays your raid group number on ready check."] = true
L["Exceptions"] = true
L["Skip Gateway Keybind-Check"] = true
L["If enabled, the addon will not check if your Gateway Shard is bound as there might be addon-combinations where this is producing a false-positive. In those cases you can enable this setting to remove the redundant alert."] = true
L["Buff Checks"] = true
L["Raid-Buff Check"] = true
L["Checks if any relevant class needs your buff"] = true
L["Healer Soulstone Check"] = true
L["Checks for Warlocks whether they have soulstoned a healer and it has at least 10m duration left. It will only check this if Soulstone is ready or has less than 30s CD left."] = true
L["Source of Magic Check"] = true
L["Checks for Evokers whether they have Source of Magic on a healer and it has at least 10m duration left."] = true
L["Blistering Scales Check"] = true
L["Checks for Evokers whether they have Blistering Scales on a player and it has at least 10m duration left."] = true
L["Symbiotic Relationship Check"] = true
L["Checks for Druids whether they have Symbiotic Relationship on a player and it has at least 10m duration left."] = true


L["Cooldowns Options"] = true
L["Enable Cooldown Checking"] = true
L["Enable cooldown checking for your cooldowns on ready check. This is only active in Heroic and Mythic Raids."] = true
L["Pull Timer"] = true
L["Pull timer used for cooldown checking."] = true
L["Unready on Cooldown"] = true
L["Automatically unready if a tracked spell is on cooldown."] = true
L["Edit Cooldowns"] = true
L["Edit the cooldowns checked on the ready check."] = true
L["Flex Raid"] = true
L["Check raid buffs up to Group 6 instead of only Group 4."] = true
L["Disable this Feature"] = true
L["Disable the Missing Raid Buffs Feature. You can re-enable it in the Setup Manager Settings."] = true

-- ============================================================================
-- UI/Options/Nicknames.lua
-- ============================================================================
L["Nicknames Options"] = true
L["Nickname"] = true
L["Set your nickname to be seen by others and used in assignments"] = true
L["Enable Nicknames"] = true
L["Globaly enable nicknames."] = true
L["Translit Names"] = true
L["Translit Russian Names"] = true
L["Automated Nickname Share Options"] = true
L["Raid"] = true
L["Guild"] = true
L["Both"] = true
L["None"] = true
L["Nickname Sharing"] = true
L["Choose who you share your nickname with."] = true
L["Nickname Accept"] = true
L["Choose who you are accepting Nicknames from"] = true
L["Manual Nickname Sync Options"] = true
L["Nickname Sync Send"] = true
L["Choose who you are synching nicknames to when pressing on the sync button"] = true
L["Nickname Sync Accept"] = true
L["Choose who you are accepting Nicknames sync requests to come from"] = true
L["Unit Frame compatibility"] = true
L["Enable Blizzard/Reskin Addons Nicknames"] = true
L["Enable Nicknames to be used with Blizzard unit frames. This should automatically work for any Addon that reskins Blizzard Frames instead of creating their own frames. This for example includes RaidFrameSettings."] = true
L["Enable Cell Nicknames"] = true
L["Enable Nicknames to be used with Cell unit frames. This requires enabling nicknames within Cell."] = true
L["Enable Grid2 Nicknames"] = true
L["Enable Nicknames to be used with Grid2 unit frames. This requires selecting the 'NSNickName' indicator within Grid2."] = true
L["Enable DandersFrames Nicknames"] = true
L["Enable Nicknames to be used with DandersFrames unit frames."] = true
L["Enable ElvUI Nicknames"] = true
L["Enable Nicknames to be used with ElvUI unit frames. This requires editing your Tags. Available options are [NSNickName] and [NSNickName:1-12]"] = true
L["Enable VuhDo Nicknames"] = true
L["Enable Nicknames to be used with VuhDo unit frames."] = true
L["Enable Unhalted UF Nicknames"] = true
L["Enable Nicknames to be used with Unhalted Unit Frames. You can choose 'NSNickName' as a tag within UUF."] = true
L["Wipe Nicknames"] = true
L["Wipe all nicknames from the database."] = true
L["Edit Nicknames"] = true
L["Edit the nicknames database stored locally."] = true
L["Confirm Wipe Nicknames"] = true
L["Are you sure you want to wipe all nicknames?"] = true

-- ============================================================================
-- UI/Options/PrivateAuras.lua
-- ============================================================================
L["Personal Private Aura Settings"] = true
L["Enabled"] = true
L["Preview/Unlock"] = true
L["Width"] = true
L["Height"] = true
L["Whether Private Aura Display is enabled"] = true
L["Preview Private Auras to move them around."] = true
L["Spacing of the Private Aura Display"] = true
L["Width of the Private Aura Display"] = true
L["Height of the Private Aura Display"] = true
L["X-Offset"] = true
L["X-Offset of the Private Aura Display"] = true
L["Y-Offset"] = true
L["Y-Offset of the Private Aura Display"] = true
L["Max-Icons"] = true
L["Maximum number of icons to display"] = true
L["Scale"] = true
L["Anchor"] = true
L["The Anchor point of the Private Aura's"] = true
L["Relative To"] = true
L["The Anchor point the Private Aura's are anchored to."] = true
L["Text-Scale"] = true
L["This will scale the size of Stacks and Duration text."] = true
L["Hide Border"] = true
L["Hide the Blizzard-border around the Player Private Auras. This includes stuff like the dispel icon."] = true
L["Disable Tooltip"] = true
L["Hide tooltips on mouseover. The frame will be clickthrough regardless."] = true
L["Personal Private Aura Text-Warning"] = true
L["Whether Private Aura Text-Warning is enabled"] = true
L["Scale"] = true
L["Scale of the Private Aura Text-Warning Anchor"] = true
L["RaidFrame Private Aura Settings"] = true
L["Whether Private Aura on Raidframes are enabled"] = true
L["Preview"] = true
L["Preview Private Auras on your own Raidframe. This only works if you actually have a frame for yourself and you can't drag this one around, use the x/y offset instead."] = true
L["Row-Grow Direction"] = true
L["Row-Grow Direction for a Grid-Style. If you select a conflicting grow direction(for example both right, or one right and the other left) the other grow option will automatically change."] = true
L["Grow Direction. If you select a conflicting grow direction(for example both right, or one right and the other left) the other grow option will automatically change."] = true
L["Icons per Row"] = true
L["How many Icons will be displayed per Row."] = true
L["Hide the Blizzard-border around the Raidframe Private Auras. This includes stuff like the dispel icon. (Tooltip is always disabled for Raidframes)"] = true
L["Hide Duration Text"] = true
L["Hide the duration text on the Private Auras."] = true
L["Show Debuff-Type Indicator"] = true
L["This will attach the Blizzard Debuff-Type Indicator to ALL Private Aura Displays. This only works if the Border is enabled. This is a global setting and it will apply to all private auras, regardless which addon is creating them."] = true
L["Private Aura Sounds"] = true
L["Edit Sounds"] = true
L["Open the Private Aura Sounds Editor"] = true
L["Use Default RAID Private Aura Sounds"] = true
L["This applies Sounds to all Raid Private Auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spellid's yourself previously this button will NOT overwrite that."] = true
L["Use Default M+ Private Aura Sounds"] = true
L["This will likely be less maintained than the Raid ones, otherwise it works the same as that one."] = true
L["Co-Tank Private Auras"] = true
L["Whether Private Auras for Co-Tanks are enabled"] = true
L["Preview Co-Tank Private Auras."] = true
L["Hide the Blizzard-border around the Co-Tank Private Auras. This includes stuff like the dispel icon."] = true

-- ============================================================================
-- UI/AnchorWindow.lua — Anchor settings popup
-- ============================================================================
L["Up"] = true
L["Down"] = true
L["Left"] = true
L["Right"] = true
L["Icon Settings"] = true
L["Bar Settings"] = true
L["Grow Direction"] = true
L["Spacing"] = true
L["Sticky Duration"] = true
L["Texture"] = true
L["Font"] = true
L["Font Size"] = true
L["Timer Font Size"] = true
L["Decimals Threshold"] = true
L["Glow Threshold"] = true
L["Zoom"] = true
L["Text X Offset"] = true
L["Text Y Offset"] = true
L["Text Position"] = true
L["Top"] = true
L["Bottom"] = true
L["Center"] = true
L["Left"] = true
L["Right"] = true
L["Timer X"] = true
L["Timer Y"] = true
L["Text Color"] = true
L["Border Color"] = true
L["Right-Aligned Text"] = true
L["Hide Swipe"] = true
L["Bar Fill Color"] = true
L["Bar Background Color"] = true
L["Bar Text Color"] = true
L["Icon X Offset"] = true
L["Icon Y Offset"] = true
L["Center Aligned"] = true
L["Size"] = true
L["Show Background Ring"] = true
L["Ring Color"] = true
L["Circle Settings"] = true

-- ============================================================================
-- UI/Options/WAImports.lua
-- ============================================================================
L["You will need to get a compatible WA fork for this yourself. The buttons provide you the wago link to each of the auras."] = true
L["Heal Absorb WA"] = true
L["Link to a WA that shows the Heal Absorb on Raidframes."] = true
L["Alleria P1 Dmg Amp"] = true
L["Displays the stacks of the dmg amp debuff on the nameplate of the 3 big adds. It is not perfect and might not display at all in some instances but it's better than nothing."] = true
L["Lura Interrupts"] = true
L["Interrupt WA for Lura P1."] = true

-- ============================================================================
-- UI/EncounterAlerts.lua
-- ============================================================================
-- Export/Import popups
L["Export Alerts"] = true
L["Import Alerts"] = true
L["Paste an alerts export string below and click Import."] = true
L["All encounter alerts"] = true
-- Left panel
L["+ Create Alert"] = true
L["Export"] = true
L["Full Reset"] = true
L["Reset"] = true
L["Additional Options"] = true
L["Import Selected Boss Alerts"] = true
L["Select a boss first."] = true
L["Enable Selected Boss Alerts"] = true
L["Disable Selected Boss Alerts"] = true
L["This will wipe all Encounter Alert data and re-import Reloe Alerts (if enabled). Continue?"] = true
L["New Alert"] = true
L["Unnamed"] = true
-- Context menus
L["Enable All"] = true
L["Disable All"] = true
L["Export Group"] = true
L["Delete Group (keep alerts)"] = true
L["Delete Group with Alerts"] = true
L["Delete group '%s' and all deletable alerts?"] = true
L["New Group..."] = true
L["Enter new group name:"] = true
L["OK"] = true
L["Export Alert"] = true
L["Add to Group"] = true
L["Move to Group"] = true
L["Duplicate"] = true
L["Remove from Group"] = true
L["Pin to Top"] = true
L["Unpin"] = true
L["Delete Alert"] = true
L["Are you sure you want to delete this alert?"] = true
-- Right panel header
L["Alert Name"] = true
L["Group"] = true
L["— No Group —"] = true
-- Inner tabs
L["Display"] = true
L["Trigger"] = true
L["Options"] = true
-- Display tab
L["Type"] = true
L["Display Text"] = true
L["Spell ID"] = true
L["Custom Icon (overrides icon in list)"] = true
L["Sticky duration (0 to disable)"] = true
L["Hide Timer Text"] = true
L["Glow Unit (player names, space seperated)"] = true
L["Glow Color"] = true
L["Color"] = true
L["Ticks (seconds into the display where ticks should appear)"] = true
L["Add tick"] = true
L["Add"] = true
-- Trigger tab
L["Boss"] = true
L["Difficulty"] = true
L["Phase"] = true
L["Trigger Times (seconds into phase)"] = true
L["Add time (s)"] = true
-- Sound tab
L["Enable Text-to-Speech"] = true
L["TTS Text (leave blank to speak the Display Text)"] = true
L["TTS Timer (seconds before the Alert expires)"] = true
L["Countdown for"] = true
L["seconds"] = true
L["Sound File"] = true
-- Load tab
L["Classes (leave all unchecked for any class)"] = true
L["Specializations (leave all unchecked for any spec)"] = true
L["Roles (leave all unchecked for any role)"] = true
L["Character Names (no server name)"] = true
L["Class / spec filters do not apply\nto addon-created alerts."] = true
L["Sound settings are fixed\nfor addon-created alerts."] = true

-- ============================================================================
-- NSUI.lua (Tabs & Sync Popup)
-- ============================================================================
L["General"] = true
L["Quality of Life"] = true
L["Ready Check"] = true
L["Reminders"] = true
L["Note-Display"] = true
L["Encounter Alerts"] = true
L["Assignments"] = true
L["Private Auras"] = true
L["WA Imports"] = true
L["Nicknames"] = true
L["Version Check"] = true
L["Shared Notes"] = true
L["Personal Notes"] = true
L["Sync Nicknames"] = true
L["%s is attempting to sync their nicknames with you."] = true
L["Preview / Move"] = true
L["Toggle a live preview of the Interrupt Display. While shown, drag it to reposition."] = true
L["Size & Position"] = true
L["Width"] = true
L["Width of the interrupt display box"] = true
L["Height"] = true
L["Height of the interrupt display box"] = true
L["X Offset"] = true
L["Horizontal offset from anchor"] = true
L["Y Offset"] = true
L["Vertical offset from anchor"] = true
L["Anchor Point"] = true
L["Which corner/edge of the display to anchor from"] = true
L["Relative Point"] = true
L["Which corner/edge of the parent frame to anchor to"] = true
L["Number Font Size"] = true
L["Size of the interrupt count number"] = true
L["Name Font Size"] = true
L["Size of the player name text"] = true
L["Number Settings"] = true
L["Number X Offset"] = true
L["Number Y Offset"] = true
L["Number Anchor Point"] = true
L["Which corner/edge of the box the number anchors from"] = true
L["Number Relative Point"] = true
L["Which corner/edge of the box the number anchors to"] = true
L["Name Settings"] = true
L["Name X Offset"] = true
L["Name Y Offset"] = true
L["Name Anchor Point"] = true
L["Which corner/edge of the box the name anchors from"] = true
L["Name Relative Point"] = true
L["Which corner/edge of the box the name anchors to"] = true
L["None"] = true
L["Number Font"] = true
L["Number Font Flags"] = true
L["Outline style for the number"] = true
L["Name Font"] = true
L["Name Font Flags"] = true
L["Outline style for the name"] = true
L["Interrupt Sound"] = true
L["Sound played when it is your turn to interrupt"] = true
L["Accept"] = true
L["Interrupt Now Color"] = true
L["Color of the display box when it's your turn to interrupt"] = true
L["Interrupt Next Color"] = true
L["Color of the display box when you are up next to interrupt"] = true
L["Interrupt Default Color"] = true
L["Color of the display box when it's not your turn to interrupt"] = true
L["Interrupt Now Text Color"] = true
L["Color of the number when it's your turn to interrupt"] = true
L["Interrupt Next Text Color"] = true
L["Color of the number when you are up next to interrupt"] = true
L["Interrupt Default Text Color"] = true
L["Color of the number when it's not your turn to interrupt"] = true
L["Show Interrupt Bar"] = true
L["Show a Bar when it's your turn to interrupt. This Bar will show through the reminder system and use your default settings for bars."] = true
