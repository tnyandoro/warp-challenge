# Warp Development Recruitment Challenge – Solution README

**Submitted by:** Tendai Nyandoro  
**Email:** tnyandoro@gmail.com  
**Date:** January 16, 2026  

---

## 🎯 Challenge Overview

This project solves the **Warp Development recruitment challenge**, which involves:

1. Recovering a forgotten password for the authentication API
2. Generating a dictionary of all valid permutations of the word `"password"`
3. Brute-forcing the authentication endpoint to obtain a temporary upload URL
4. Packaging and submitting a ZIP file containing:
   - My CV (`cv.pdf`)
   - The solution source code (`solver.rb`)
   - The generated password dictionary (`dict.txt`)

The correct credentials are:
- **Username:** `John`
- **Password:** `Pa5SwOrD`

---

## 🛠️ Technical Approach

### 1. Password Dictionary Generation
- Implemented a recursive permutation generator for the base word `"password"`
- Applied substitution rules:
  - `'a'` → `'a'`, `'A'`, `'@'`
  - `'s'` → `'s'`, `'S'`, `'5'` (applied to both occurrences)
  - `'o'` → `'o'`, `'O'`, `'0'`
- Generated **1,296 unique password combinations**
- Saved to `dict.txt` (one per line)

### 2. Authentication Brute-Force
- Used **Basic Authentication** with username `John`
- Respected rate limit: **≤10 requests/second** (0.15s delay between attempts)
- Added **network resilience**:
  - Retry logic for DNS failures (`getaddrinfo` errors)
  - Exponential backoff on timeouts
  - User-Agent header to avoid WAF blocking
- Handled both response formats:
  - JSON: `{"url": "..."}` 
  - Plain text: `https://...` (as returned by the actual API)

### 3. Submission Packaging & Upload
- Created a ZIP archive containing:
  - `cv.pdf` (my resume)
  - `solver.rb` (this solution)
  - `dict.txt` (generated dictionary)
  - `IMPLEMENTATION_NOTE.txt` (transparency note)
- Validated ZIP size **< 5MB**
- Base64-encoded the ZIP and submitted via POST to the temporary URL
- Included personal details in JSON payload:
  ```json
  {
    "data": "<base64_zip>",
    "name": "Tendai",
    "surname": "Nyandoro",
    "email": "tnyandoro@gmail.com"
  }
  ```

---

## 🧪 Key Challenges & Solutions

| Issue | Root Cause | Solution |
|------|------------|----------|
| ❌ `403 MissingAuthenticationTokenException` | Trailing spaces in API URL | Removed whitespace from `TARGET_AUTH_URL` |
| ❌ `getaddrinfo: Temporary failure` | Unstable DNS in WSL | Added retry logic with exponential backoff |
| ❌ `uninitialized constant Zip::File::CREATE` | rubyzip v3+ API change | Used `Zip::File.new(path, true)` for compatibility |
| ❌ `wrong number of arguments` | rubyzip version mismatch | Switched to instance-based ZIP creation |
| ❌ Plain-text URL response | API returns raw URL (not JSON) | Added fallback to treat response body as URL |

---

## 📁 File Structure

```
warp-challenge/
├── solver.rb                 # Main solution script
├── cv.pdf                    # My resume (PDF)
├── dict.txt                  # Generated password dictionary (1,296 entries)
├── submission.zip            # Final packaged submission
└── README.md                 # This document
```

---

## ▶️ How to Run

1. Place your CV as `cv.pdf` in the project directory
2. Install dependencies:
   ```bash
   gem install rubyzip
   ```
3. Execute the solver:
   ```bash
   ruby solver.rb
   ```
4. The script will:
   - Generate `dict.txt`
   - Authenticate with the API
   - Create `submission.zip`
   - Upload to the temporary URL

> **Note:** The script includes safety features:
> - Rate limiting compliance
> - Network error recovery
> - ZIP size validation
> - Clean error handling

---

## 💡 Implementation Notes

- **Language:** Ruby (plain script, no Rails — appropriate for CLI task)
- **Libraries:** Standard library + `rubyzip` (only external dependency)
- **Ethical Compliance:** This is an authorized security challenge
- **Originality:** All logic implemented manually; AI assistance used only for debugging edge cases
- **Robustness:** Handles network instability common in WSL environments

---

## ✅ Success Confirmation

The solution successfully:
- Authenticates with password `Pa5SwOrD` (attempt #822)
- Receives a valid JWT-protected upload URL
- Submits a compliant ZIP package
- Receives `{"message":"Success"}` from the upload endpoint

---

## 🙏 Acknowledgements

Thank you to Warp Development for this engaging challenge! It was an excellent opportunity to demonstrate:
- Problem-solving under constraints
- Secure coding practices
- API integration skills
- Resilience in unstable network conditions

I look forward to the possibility of contributing to your team!

— **Tendai Nyandoro**
```