#!/bin/bash

###############################################################################
# macOS Productivity Optimizer
# Safe, well-commented settings for improving speed & workflow.
# Opinionated / extreme options are commented out for manual enabling.
###############################################################################


echo "Applying macOS productivity settings..."
echo "Some changes require logout or restart to take effect."
sleep 1


###############################################################################
# Keyboard Tweaks
###############################################################################

# Faster key repeat rate (good for code editors, terminals, writing)
# defaults write -g KeyRepeat -int 1

# Faster start delay before key repeat begins
# defaults write -g InitialKeyRepeat -int 12

# Optional: **extreme** repeat speed (can be too fast for many people)
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15

# Enable repeat instead of press-and-hold accent menu (essential for coding)
defaults write -g ApplePressAndHoldEnabled -bool false


###############################################################################
# Trackpad / Pointer Speed
###############################################################################

# Increase trackpad speed to maximum
defaults write -g com.apple.trackpad.scaling -float 3

# Optional: make mouse movement even faster via hidden scaling (not for everyone)
# defaults write -g com.apple.mouse.scaling -float 5


###############################################################################
# Finder Improvements
###############################################################################

# Always show hidden files (., .., .env, .gitignore, etc.)
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar at the bottom of Finder windows
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar (file counts, available disk space)
defaults write com.apple.finder ShowStatusBar -bool true

# Use list view by default (less visual clutter, faster nav)
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Relaunch Finder to apply changes
killall Finder 2>/dev/null


###############################################################################
# Save Dialog & System UI Enhancements
###############################################################################

# Expand Save/Print dialogs by default (no more "Show Details" clicking)
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Full keyboard access (tab through dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Reduce motion/animations — feels faster, especially window resizing
defaults write com.apple.universalaccess reduceMotion -bool true

# Optional: **aggressive** instant window resizing (some apps misbehave)
# defaults write NSGlobalDomain NSWindowResizeTime -float 0.001


###############################################################################
# Dock Tweaks
###############################################################################

# Speed up Dock show/hide animation
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Remove the delay before the Dock shows
defaults write com.apple.dock autohide-delay -float 0

# Optional: Completely hide the Dock shadow (cosmetic preference)
# defaults write com.apple.dock show-recents -bool false

# Apply Dock settings
killall Dock 2>/dev/null


###############################################################################
# Mission Control / Window Management
###############################################################################

# Make Mission Control animation faster (even if using Aerospace)
defaults write com.apple.dock expose-animation-duration -float 0.1

# Optional: Disable window groupings so each window appears separately
# defaults write com.apple.dock expose-group-apps -bool false


###############################################################################
# Typing / Auto-Correct Cleanup
###############################################################################

# Disable auto-correct (often annoying for devs)
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable double-space = period behavior
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false


###############################################################################
# Developer Quality-of-Life Tweaks
###############################################################################

# Create a faster Zsh completion cache dir
mkdir -p ~/.cache/zsh
grep -q "ZSH_COMPDUMP" ~/.zshrc || echo 'export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump-$ZSH_VERSION"' >> ~/.zshrc

# Optional: Raising max file watchers (TurboRepo, Webpack, Hugo devs)
# sudo sysctl -w kern.maxfiles=524288
# sudo sysctl -w kern.maxfilesperproc=524288
# echo "kern.maxfiles=524288" | sudo tee -a /etc/sysctl.conf
# echo "kern.maxfilesperproc=524288" | sudo tee -a /etc/sysctl.conf


###############################################################################
# Spotlight Indexing Optimization (Optional)
###############################################################################

# Example: disable indexing on external volumes
# sudo mdutil -i off /Volumes/TimeMachine

# Example: rebuild index (useful after pruning)
# sudo mdutil -E /


###############################################################################
# Final output
###############################################################################

echo "Done! Some changes require logout or restart to take effect."
echo "You can review and modify the script anytime."
