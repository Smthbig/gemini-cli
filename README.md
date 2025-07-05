# Terminal Gemini AI CLI – v4.2

Terminal-based AI assistant powered by Gemini 2.5 with Copilot mode, file analysis, code generation/improvement, and persistent conversations.

---

## 📂 File: `gmcli.sh`

**Author:** [Mohan Sharma](https://github.com/mrajauriya)  
**License:** MIT  
**Dependencies:** `bash`, `curl`, `jq`

---

## 🚀 Features

- 🔐 Secure API key storage
- 🧠 Chat with Gemini 2.5 (Flash model)
- 📜 Persistent conversation history
- ✨ Copilot mode: generate, explain, or improve code
- 🔍 Analyze large files in chunks
- 🛠 Configurable model, temperature, and max tokens
- 📝 Save/load instructions for system behavior
- 🧹 Automatic summarization of long chat history

---

## 📦 Installation

```bash
curl -o gmcli.sh https://raw.githubusercontent.com/mrajauriya/gmcli/main/gmcli.sh
chmod +x gmcli.sh
./gmcli.sh
```

> Make sure you have `jq` and `curl` installed.

Install them on Termux:
```bash
pkg install jq curl
```

Or on Debian/Ubuntu:
```bash
sudo apt install jq curl
```

---

## 🛠 Setup

On first run, enter your Gemini API key. You can also edit the config later:

```bash
echo 'YOUR_API_KEY_HERE' > ~/.smrtask_gemini/config.sh
```

To change default system instructions:
```bash
echo 'You are a helpful assistant.' > ~/.smrtask_gemini/instructions.txt
```

---

## 🧪 Usage

Run the script:
```bash
./gmcli.sh
```
Then interact via menu:

1. Chat with Gemini
2. View or reset conversation
3. Copilot coder mode (generate/explain/improve code)
4. Analyze files
5. Configure model, tokens, temperature, and instructions

---

## ✨ Copilot Mode

- **Generate Code** – Provide a description and filename
- **Explain Code** – Analyze an existing file line-by-line
- **Improve Code** – Give modification instructions for existing files

---

## 📁 Config Directory

All settings, history, and instructions are stored in:
```
~/.smrtask_gemini/
├── config.sh           # API key & model config
├── history.json        # Chat memory
└── instructions.txt    # Custom system instructions
```

---

## 🤖 Model Info

By default, uses:
- **Model:** `gemini-2.5-flash-preview-04-17`
- **Max Tokens:** `8192`
- **Temperature:** `0.7`
- **Top-K:** `1`
- **Top-P:** `0.95`

These can be adjusted in the script menu.

---

## 🧠 Chat History

Persistent across sessions and summarized automatically if it grows too long. Summarization keeps the assistant aware of previous context efficiently.

---

## 🧹 To Reset Everything

Delete the config directory:
```bash
rm -rf ~/.smrtask_gemini
```

---

## 🪪 License

Apache License © [Mohan Sharma]([https://github.com/mrajauriya])

---

> Made with ❤️ in Terminal
