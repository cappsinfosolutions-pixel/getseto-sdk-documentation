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
| `Pending` | Application submitted; awaiting review. |
| `ReviewPending` | Documents uploaded; assigned for manual review. |
| `Assigned` | Application assigned to a verifier. |
| `OnHold` | Application is on hold for additional information. |
| `Approved` | KYC approved successfully. |
| `ApprovedBoPending` | KYC approved; back-office processing is pending. |
| `ApprovedCancelled` | KYC was approved but subsequently cancelled. |
| `Rejected` | KYC rejected; applicant must re-apply. |
| `SystemRejected` | Rejected automatically by the system (e.g. duplicate records). |
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
    baseUrl: "https://api.getseto.com"
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

## See also

- [Flutter Integration Guide](flutter-integration.md) — how to launch the SDK and receive the `applicationId`
- [Theming Guide](theming.md) — customise the SDK appearance
- [Troubleshooting](troubleshooting.md) — common issues and fixes
