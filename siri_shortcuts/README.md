# 📱 Siri Shortcuts for NYT Crossword

This directory contains Siri Shortcuts that provide convenient voice-activated access to the NYT crossword script running on a remote server. Each shortcut uses SSH to execute the crossword script remotely and can be triggered via Siri voice commands.

## 🎯 Available Shortcuts

### 📋 **Print Today's Crossword** (`print_today_crossword.shortcut`)
**Voice Command**: *"Hey Siri, print today's crossword"*  
**Function**: Downloads and prints the current day's crossword puzzle  
**Script Command**: `./get_crossword.sh -d <today's date>`

---

### 📋 **Print Yesterday's Crossword** (`print_yesterday_crossword.shortcut`)  
**Voice Command**: *"Hey Siri, print yesterday's crossword"*  
**Function**: Downloads and prints yesterday's crossword puzzle  
**Script Command**: `./get_crossword.sh -d <yesterday's date>`

---

### 📋 **Print Tomorrow's Crossword** (`print_tomorrow_crossword.shortcut`)
**Voice Command**: *"Hey Siri, print tomorrow's crossword"*  
**Function**: Downloads and prints tomorrow's crossword puzzle  
**Script Command**: `./get_crossword.sh -d <tomorrow's date>`
**Smart Timing**: Only works after puzzle release times:
- **Sunday-Friday**: After 10:00 PM  
- **Saturday**: After 6:00 PM

---

### 🎲 **Print Random Crossword** (`print_random_crossword.shortcut`)
**Voice Command**: *"Hey Siri, print a random crossword"*  
**Function**: Downloads and prints a random crossword from the NYT archive  
**Script Command**: `./get_crossword.sh -r` (weighted random selection)

---

### 📅 **Print Random Weekday Crossword** (`print_random_weekday_crossword.shortcut`)
**Voice Command**: *"Hey Siri, print random weekday crossword"*  
**Function**: Prompts for a day of the week, then downloads a random puzzle from that day  
**Script Command**: `./get_crossword.sh -w <selected day>`  
**Interactive**: Asks user to choose day during execution (Monday=easy, Saturday=hard)  
**Difficulty Guide**:
- **Monday**: Easiest puzzles, perfect for beginners
- **Tuesday-Wednesday**: Moderate difficulty
- **Thursday**: Trickier with wordplay and themes
- **Friday**: Challenging but straightforward
- **Saturday**: Hardest, themeless puzzles
- **Sunday**: Large themed puzzles

---

### 📅 **Print Specific Crossword** (`print_specific_crossword.shortcut`)
**Voice Command**: *"Hey Siri, print a specific crossword"*  
**Function**: Prompts for a date, then downloads that puzzle  
**Script Command**: `./get_crossword.sh -d <specified date>`  
**Interactive**: Asks user to input date during execution

## ⚙️ Setup Requirements

### Prerequisites
- **Apple Device** with Shortcuts app
- **Remote Server** with the crossword script installed and configured
- **SSH Access** to the remote server from your iOS device
- **Printer** configured on the remote server
- **Valid NYT Cookies** stored on the remote server

### Network Requirements
- Shortcuts device and server must have network connectivity
- SSH port (22) accessible from Shortcuts device to server
- Consider VPN if accessing server over internet

## 🛠️ Installation & Configuration

### Step 1: Download Shortcuts
1. Transfer `.shortcut` files to your device via:
   - AirDrop from Mac
   - Email attachment
   - iCloud Drive/Files app
   - Direct download from GitHub

### Step 2: Import and Configure
1. **Open each shortcut file** on your device
2. **Tap "Add Shortcut"** when prompted
3. **Configure import-time prompts** for each shortcut:

#### Required Configuration (prompted at import):
- **🖥️ Remote Host**: IP address or hostname of your server
  ```
  Examples:
  192.168.1.100
  my-server.local  
  crossword.mydomain.com
  ```

- **👤 Username**: SSH username for the server
  ```
  Examples:
  admin
  crossword-user
  ```

- **💻 Default Command**: Base command to execute the script
  ```
  Examples:
  cd /home/crossword-user/crossword && ./get_crossword.sh
  cd ~/nyt_crossword && ./get_crossword.sh -p HP_Printer
  cd /opt/crossword && ./get_crossword.sh -l -s
  ```

### Step 3: SSH Authentication Setup
Each shortcut will prompt for SSH authentication when first run:
- **Password**: Enter your SSH password
- **SSH Key**: Use SSH key authentication (recommended)

For SSH key setup:
```bash
# On your server
ssh-keygen -t rsa -b 4096 -C "ios-shortcuts"
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Copy private key to iOS Shortcuts (when prompted)
cat ~/.ssh/id_rsa
```

### Step 4: Test Installation
1. **Run each shortcut manually** first to verify configuration
2. **Test voice commands** with Siri
3. **Verify output** - check that puzzles print correctly
4. **Adjust settings** as needed in Shortcuts app

## 🎙️ Voice Commands

Once configured, you can use these voice commands with Siri:

```
"Hey Siri, print today's crossword"
"Hey Siri, print yesterday's crossword"  
"Hey Siri, print tomorrow's crossword"
"Hey Siri, print a random crossword"
"Hey Siri, print a random weekday crossword"
"Hey Siri, print a specific crossword"
```

## 🔧 Customization Options

### Modifying Commands
You can edit shortcuts to customize the crossword script commands:

**Format Options**:
```bash
# Large print
./get_crossword.sh -l

# Left-handed layout  
./get_crossword.sh -L

# Ink saver
./get_crossword.sh -i

# Multiple options
./get_crossword.sh -l -L -i
```

**Output Options**:
```bash
# Save to file instead of printing
./get_crossword.sh -s

# Specify printer
./get_crossword.sh -p "Brother_Printer"

# Dry run (test mode)
./get_crossword.sh -n
```

**Advanced Options**:
```bash
# Use configuration defaults
DEFAULT_LARGE_PRINT=true ./get_crossword.sh

# Verbose output
VERBOSITY=2 ./get_crossword.sh

# Custom save location
SAVE_DIR=~/crosswords ./get_crossword.sh -s
```

### Adding New Shortcuts
To create additional shortcuts:

1. **Duplicate existing shortcut** in Shortcuts app
2. **Modify the SSH command** to use different options
3. **Change the name and Siri phrase**
4. **Test the new shortcut**
5. **Export and share** if useful to others

### Example Custom Shortcuts
```bash
# Specific weekday shortcuts (fixed days)
./get_crossword.sh -w Monday      # "Hey Siri, easy Monday puzzle"
./get_crossword.sh -w Saturday    # "Hey Siri, hard Saturday puzzle"

# Weekend puzzles only (Friday-Sunday)  
./get_crossword.sh -w Friday
./get_crossword.sh -w Saturday
./get_crossword.sh -w Sunday

# Large print weekday puzzles
./get_crossword.sh -w Tuesday -l

# Save puzzle to specific directory
SAVE_DIR=~/weekend-puzzles ./get_crossword.sh -s

# Solution mode for checking answers
./get_crossword.sh -S
```

## 🚨 Troubleshooting

### Common Issues

**"Cannot connect to server"**
- Check server IP/hostname
- Verify network connectivity  
- Confirm SSH service is running
- Check firewall settings

**"Authentication failed"**  
- Verify username is correct
- Check SSH password/key
- Ensure user has access to crossword script
- Test SSH connection manually

**"Command not found"**
- Verify script path in default command
- Check if script is executable (`chmod +x get_crossword.sh`)
- Ensure dependencies (curl, jq) are installed
- Test command directly via SSH

**"No printer configured"**
- Add `-p PrinterName` to default command
- Or use `-s` to save to file instead
- Check printer setup on server: `lpstat -p`

**"Cookie file not found"**
- Ensure NYT cookies are properly exported on server
- Check cookie file path in config.sh
- Re-export cookies if expired

### Debug Mode
Add debug flags to your default command:
```bash
# Verbose output
VERBOSITY=2 ./get_crossword.sh

# Dry run to test without printing
./get_crossword.sh -n

# Save to file for inspection
./get_crossword.sh -s
```

### Manual Testing  
Before relying on shortcuts, test the setup manually:
```bash
# SSH to server manually
ssh username@hostname

# Run crossword command directly
cd /path/to/crossword && ./get_crossword.sh -n

# Test specific functionality
./quick_test.sh
```

## 🔒 Security Considerations

### SSH Security
- **Use SSH keys** instead of passwords when possible
- **Limit SSH access** to specific IP ranges if needed
- **Regular key rotation** for enhanced security
- **Monitor SSH logs** for unauthorized access attempts

### Network Security  
- **Use VPN** when accessing over internet
- **Firewall rules** to restrict SSH access
- **Regular security updates** on the server

### iOS Security
- **Shortcuts contain sensitive info** (hostnames, usernames)
- **Be cautious when sharing** shortcuts with others
- **Review permissions** granted to Shortcuts app

## 📋 Summary

These shortcuts provide seamless voice-activated access to your NYT crossword collection:

- **🎯 Five different puzzle selection modes** - today, yesterday, tomorrow, random, specific date
- **⚙️ Flexible configuration** - customize commands, printers, and options
- **🎙️ Voice activation** - hands-free operation via Siri
- **🔒 Secure SSH connection** - encrypted communication to your server
- **🖨️ Direct printing** - puzzles automatically sent to your printer

Perfect for morning routines, quick puzzle printing, or accessible crossword solving!