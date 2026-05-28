# GetSetO API — Application Status

This guide explains how to query the real-time status of a KYC application from your own backend or server-side code using the GetSetO API.

---

## Overview

After a user completes the KYC journey inside the SDK, your app receives an `applicationId` in the `onComplete` callback. You can use this ID at any time to fetch the current status of that application from the GetSetO backend.

All API requests are:

- Authenticated with your **Tenant API Key** (sent as an HTTP header)
- Encrypted with your **Secret Key** (AES-256-CBC)

Both keys are provided to you by GetSetO during onboarding.

---

## Prerequisites

| Item | Description |
|---|---|
| **Tenant API Key** | Identifies your organisation. Sent in every request header. |
| **Secret Key** | 32-character UTF-8 string used to encrypt and decrypt all payloads. Keep this secret — never expose it in client-side code. |
| **Application ID** | The integer `applicationId` you received in the `onComplete` callback when the user finished the KYC journey. |

---

## Endpoint

```
POST /api/tenant-api/status
Content-Type: application/json
ApiKey: YOUR_TENANT_API_KEY
```

---

## How encryption works

The API uses a symmetric **AES-CBC / PKCS7** scheme. Both the request body you send and the response body you receive are encrypted with the same Secret Key.

**Encryption steps (for a request):**

1. Build the inner JSON payload: `{ "Data": "<applicationId>" }`
2. Generate a random 16-byte IV.
3. Encrypt the JSON bytes using AES-CBC with PKCS7 padding and your Secret Key (UTF-8 encoded).
4. Prepend the IV to the ciphertext bytes: `[IV bytes (16)] + [ciphertext bytes]`
5. Base64-encode the combined byte array.
6. Wrap the result in the outer envelope and POST it: `{ "Data": "<base64 string>" }`

**Decryption steps (for a response):**

1. Receive the JSON response: `{ "Data": "<base64 string>" }`
2. Base64-decode the `Data` value.
3. Extract the first 16 bytes as the IV; the remaining bytes are the ciphertext.
4. Decrypt using AES-CBC with PKCS7 padding and your Secret Key.
5. Parse the decrypted JSON string into the `ApplicationStatus` object.

---

## Request

### Plain text payload

```json
{
  "Data": "12345"
}
```
"12345" is the **Application ID as a string**.

### HTTP request body

```json
{
  "Data": "<AES-CBC encrypted, Base64-encoded Plain text payload>"
}
```


---

## Response

### HTTP response body

```json
{
  "Data": "<AES-CBC encrypted, Base64-encoded response>"
}
```

### Decrypted inner response

```json
{
  "ApplicationStatus": "Approved",
  "LastStageCompleted": "IPV",
  "Mobile": "98XXXXXXXX",
  "Email": "user@example.com"
}
```

### Response fields

| Field | Type | Description |
|---|---|---|
| `ApplicationStatus` | string (enum) | Current status of the KYC application. See the table below. |
| `LastStageCompleted` | string | Identifier of the last KYC stage the applicant successfully completed. |
| `Mobile` | string | Applicant's registered mobile number. |
| `Email` | string | Applicant's registered email address. |

### `ApplicationStatus` values

| Value | Meaning |
|---|---|
| `Pending` | Application not yet completed; awaiting user to complete all steps. |
| `ReviewPending` | Application submitted; awaiting verifier review. |
| `Assigned` | Application assigned to a verifier. |
| `OnHold` | Application is on hold by verifier. |
| `Approved` | Application approved successfully. |
| `ApprovedBoPending` | Application approved; back-office processing is pending. |
| `ApprovedCancelled` | Application was approved but subsequently cancelled. |
| `Rejected` | Application rejected; applicant must re-submit after clearing all issues raised by verifier. |
| `SystemRejected` | Application rejected by the back-office system. |
| `Cancelled` | Application was cancelled. |

---

## Code example

### C\#

No external packages required — uses the built-in `System.Security.Cryptography.Aes` and `System.Net.Http.HttpClient`.

```csharp
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

public class GetSetoApiClient
{
    private readonly HttpClient _httpClient;
    private readonly string _secretKey;

    public GetSetoApiClient(string tenantApiKey, string secretKey, string baseUrl)
    {
        _secretKey = secretKey;
        _httpClient = new HttpClient { BaseAddress = new Uri(baseUrl) };
        _httpClient.DefaultRequestHeaders.Add("ApiKey", tenantApiKey);
    }

    public async Task<ApplicationStatusResult> GetApplicationStatusAsync(int applicationId)
    {
        // 1. Build and encrypt the inner payload
        var innerPayload = JsonSerializer.Serialize(new { Data = applicationId.ToString() });
        var encryptedData = AesEncrypt(innerPayload);

        // 2. POST to the API
        var response = await _httpClient.PostAsJsonAsync("/api/tenant-api/status", new { Data = encryptedData });
        response.EnsureSuccessStatusCode();

        // 3. Decrypt the response
        var responseEnvelope = await response.Content.ReadFromJsonAsync<DataEnvelope>();
        var decryptedJson = AesDecrypt(responseEnvelope!.Data);
        return JsonSerializer.Deserialize<ApplicationStatusResult>(decryptedJson)!;
    }

    private string AesEncrypt(string plainText)
    {
        var key = Encoding.UTF8.GetBytes(_secretKey); // must be 32 bytes for AES-256

        using var aes = Aes.Create();
        aes.GenerateIV();
        aes.Key = key;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        using var encryptor = aes.CreateEncryptor();
        var plainBytes = Encoding.UTF8.GetBytes(plainText);
        var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

        // Prepend IV to ciphertext, then Base64-encode
        var combined = new byte[aes.IV.Length + cipherBytes.Length];
        aes.IV.CopyTo(combined, 0);
        cipherBytes.CopyTo(combined, aes.IV.Length);
        return Convert.ToBase64String(combined);
    }

    private string AesDecrypt(string cipherText)
    {
        var key = Encoding.UTF8.GetBytes(_secretKey);
        var combined = Convert.FromBase64String(cipherText);

        var iv = combined[..16];
        var cipherBytes = combined[16..];

        using var aes = Aes.Create();
        aes.Key = key;
        aes.IV = iv;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;

        using var decryptor = aes.CreateDecryptor();
        var plainBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);
        return Encoding.UTF8.GetString(plainBytes);
    }
}

public record DataEnvelope(string Data);
public record ApplicationStatusResult(string ApplicationStatus, string LastStageCompleted, string Mobile, string Email);
```

**Usage:**

```csharp
var client = new GetSetoApiClient(
    tenantApiKey: "YOUR_TENANT_API_KEY",
    secretKey: "YOUR_32_CHAR_SECRET_KEY_________",
    baseUrl: "API_BASE_URL_PROVIDED_TO_YOU"
);

var status = await client.GetApplicationStatusAsync(applicationId: 12345);

Console.WriteLine(status.ApplicationStatus);   // e.g. "Approved"
Console.WriteLine(status.LastStageCompleted);  // e.g. "IPV"
Console.WriteLine(status.Mobile);
Console.WriteLine(status.Email);
```

---

## Error responses

| HTTP status | Meaning |
|---|---|
| `400 Bad Request` | Missing or invalid `Data` field, or the decrypted Application ID is invalid. |
| `401 Unauthorized` | Missing or incorrect `ApiKey` header. |
| `404 Not Found` | No application found for the given ID under your tenant. |
| `500 Internal Server Error` | Unexpected server error. Contact GetSetO support. |

---

## Security notes

- Store your **Secret Key** in a secure secrets manager (e.g. AWS Secrets Manager, Azure Key Vault). Never hard-code it or commit it to source control.
- Call this API only from your **server-side backend**. Never call it directly from the Flutter app — doing so would expose your Secret Key to end users.
- Rotate your Secret Key periodically and update your backend configuration accordingly.

---

## Get Access Token (Server-to-Server)

This endpoint lets your backend generate a short-lived access token for a specific mobile number. You pass this token to the Flutter SDK so the user can start the KYC journey **without going through the OTP login inside the SDK**.

> **Think of it this way:** Normally the SDK asks the user for their mobile number and OTP by itself. With this flow, *you* handle the OTP in your own app, and once verified, you ask GetSetO for a "pass" (the access token) that lets the SDK skip its own login screens.

### When should you use this?

Use this endpoint when:

- Your app already has its own OTP or authentication flow and you don't want to ask the user to verify their mobile a second time inside the SDK.
- You want to keep the login experience consistent with your own app's design.
- You want tighter control over when and how users are authenticated before starting KYC.

### Important — keep your Secret Key on the server

**Your Secret Key must never appear in your Flutter (client-side) app.** This call must always come from your own backend server. Your Flutter app asks *your server* for the token, and your server calls GetSetO.

```
Your Flutter App
      │
      │  (your own API — you design this)
      ▼
Your Backend Server
      │
      │  POST /api/tenant-api/access-token
      │  (server-to-server, encrypted with Secret Key)
      ▼
GetSetO API  →  returns Access Token
      │
      ▼
Your Backend Server returns the Token to your Flutter App
      │
      ▼
Flutter SDK uses the Token to start the KYC journey
```

### Endpoint

```
POST /api/tenant-api/access-token
Content-Type: application/json
ApiKey: YOUR_TENANT_API_KEY
```

### Request

Build the plain-text payload below, encrypt it with your Secret Key using the same AES-CBC method described above, and send it wrapped in `DataObject`.

**Plain-text payload (before encryption):**

```json
{
  "Mobile": "9876543210",
  "MobileRelationshipId": 1,
  "ClientCode": "",
  "Source": 1
}
```

**Field reference:**

| Field | Type | Required | Description |
|---|---|---|---|
| `Mobile` | string | Yes | The user's 10-digit mobile number. Must begin with 5, 6, 7, 8, or 9. |
| `MobileRelationshipId` | integer | Conditional | Relationship type ID (e.g. `1` for "Self"). Provided to you during tenant onboarding. Pass an empty string for source=Modification. |
| `ClientCode` | string | Conditional | Your client code if source is Modification. Pass an empty string for source=KYC. |
| `Source` | integer | Yes | Journey type. `1` = KYC (default), `4` = Modification. See table below. |

**`Source` values:**

| Value | Description |
|---|---|
| `1` | KYC — standard new account onboarding journey (most common). |
| `4` | Modification — update details on an existing account. |

**HTTP request body:**

```json
{
  "Data": "<AES-CBC encrypted, Base64-encoded plain-text payload>"
}
```

### Response

> Unlike the Status endpoint, the response from this endpoint is **plain JSON — not encrypted**. Read it directly without decrypting.

**HTTP response body:**

```json
{
  "Token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "Mobile": "9876543210",
  "MobileRelationshipId": 1,
  "ClientCode": "",
  "Source": 1,
  "AppExists": true
}
```

**Response fields:**

| Field | Type | Description |
|---|---|---|
| `Token` | string | The JWT access token. Pass this to the Flutter SDK. |
| `AppExists` | boolean | `true` = a KYC application already exists for this mobile number (the SDK will **resume** it). `false` = no existing application (the SDK will **start a fresh** journey). |
| `Mobile` | string | The mobile number you sent (echoed back for confirmation). |
| `MobileRelationshipId` | integer | The relationship ID you sent (echoed back). |
| `ClientCode` | string | The client code you sent (echoed back). |
| `Source` | integer | The source you sent (echoed back). |

> You do not need to handle `AppExists` differently in Flutter — the SDK takes care of resume vs. new journey automatically based on the token.

### C\# example

This example extends the same `GetSetoApiClient` class shown in the Status section above. The `AesEncrypt` helper is the same one defined there.

```csharp
/// <summary>
/// Calls GetSetO server-to-server to generate an access token for a verified mobile number.
/// Call this ONLY from your backend after your own OTP verification is complete.
/// </summary>
public async Task<AccessTokenResponse> GetAccessTokenAsync(string mobile, int mobileRelationshipId)
{
    // 1. Build the plain-text payload
    var innerPayload = JsonSerializer.Serialize(new
    {
        Mobile = mobile,
        MobileRelationshipId = mobileRelationshipId,
        ClientCode = "",  // pass your client code here if your workflow requires it
        Source = 1        // 1 = KYC journey
    });

    // 2. Encrypt the payload (same AesEncrypt helper as the Status endpoint)
    var encryptedData = AesEncrypt(innerPayload);

    // 3. POST to GetSetO
    var response = await _httpClient.PostAsJsonAsync(
        "/api/tenant-api/access-token",
        new { Data = encryptedData }
    );
    response.EnsureSuccessStatusCode();

    // 4. The response is plain JSON — no decryption needed
    var result = await response.Content.ReadFromJsonAsync<AccessTokenResponse>();
    return result!;
}

// Response model
public record AccessTokenResponse(
    string Token,
    bool AppExists,
    string Mobile,
    int MobileRelationshipId,
    string ClientCode,
    int Source
);
```

**Usage — your backend controller:**

```csharp
// Your backend exposes this endpoint to your Flutter app.
// It verifies the OTP first, then fetches the GetSetO token.
[HttpPost("/api/kyc/access-token")]
public async Task<IActionResult> GetKycAccessToken([FromBody] KycTokenRequest request)
{
    // 1. Verify OTP using your own system (not shown here)
    var otpValid = await _otpService.VerifyAsync(request.Mobile, request.Otp);
    if (!otpValid)
        return Unauthorized("Invalid OTP");

    // 2. Fetch the GetSetO access token
    var tokenData = await _getSetoClient.GetAccessTokenAsync(
        mobile: request.Mobile,
        mobileRelationshipId: request.MobileRelationshipId
    );

    // 3. Return only what the Flutter app needs
    return Ok(new
    {
        token = tokenData.Token,
        mobile = tokenData.Mobile,
        mobileRelationshipId = tokenData.MobileRelationshipId,
        source = tokenData.Source,
        appExists = tokenData.AppExists  // useful if you want to show "resuming..." in your UI
    });
}
```

> **Never return your Secret Key or raw GetSetO API credentials to the Flutter app.** Return only the `Token` and the fields your app needs.

### Error responses

Every error from this endpoint (and all GetSetO API endpoints) returns the same JSON body shape, regardless of HTTP status:

```json
{
  "Message": "A human-readable description of what went wrong.",
  "ErrorCode": 50002,
  "ErrorState": 0
}
```

| HTTP Status | `ErrorCode` | When it happens |
|---|---|---|
| `401 Unauthorized` | `50009` | `ApiKey` header is missing, incorrect, or the tenant account is deactivated. |
| `422 Unprocessable Entity` | `50001` | `Mobile` field is missing or has an invalid format. Must be 10 digits and begin with 5, 6, 7, 8, or 9. |
| `422 Unprocessable Entity` | `50002` | `MobileRelationshipId` is missing or is `0`. |
| `400 Bad Request` | `50003` | A KYC application already exists for this mobile number but under a **different** `MobileRelationshipId`. The `Message` field includes the existing application number and relationship name. |
| `500 Internal Server Error` | `50006`–`50012` | Unexpected server-side error. Contact GetSetO support. |

> **`ErrorState`** is an internal byte used by GetSetO support to pinpoint exactly which check failed within an error code. You do not need to act on it — use `ErrorCode` to identify the type of error.

---

## Security notes

- Store your **Secret Key** in a secure secrets manager (e.g. AWS Secrets Manager, Azure Key Vault). Never hard-code it or commit it to source control.
- Call this API only from your **server-side backend**. Never call it directly from the Flutter app — doing so would expose your Secret Key to end users.
- Rotate your Secret Key periodically and update your backend configuration accordingly.

---

## See also

- [Flutter Integration Guide](flutter-integration.md) — how to launch the SDK and receive the `applicationId`
- [Flutter Integration Guide — Advanced Login](flutter-integration.md#advanced-access-token-login) — how to use the access token to skip the SDK's OTP screens
- [Theming Guide](theming.md) — customise the SDK appearance
- [Troubleshooting](troubleshooting.md) — common issues and fixes
