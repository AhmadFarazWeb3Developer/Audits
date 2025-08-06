const fs = require("fs");
const path = require("path");

const hex1 =
  "4d 48 67 33 5a 44 45 31 59 6d 4a 68 4d 6a 5a 6a 4e 54 49 7a 4e 6a 67 7a 59 6d 5a 6a 4d 32 52 6a 4e 32 4e 6b 59 7a 56 6b 4d 57 49 34 59 54 49 33 4e 44 51 30 4e 44 63 31 4f 54 64 6a 5a 6a 52 6b 59 54 45 33 4d 44 56 6a 5a 6a 5a 6a 4f 54 6b 7a 4d 44 59 7a 4e 7a 51 30";

const hex2 =
  "4d 48 67 32 4f 47 4a 6b 4d 44 49 77 59 57 51 78 4f 44 5a 69 4e 6a 51 33 59 54 59 35 4d 57 4d 32 59 54 56 6a 4d 47 4d 78 4e 54 49 35 5a 6a 49 78 5a 57 4e 6b 4d 44 6c 6b 59 32 4d 30 4e 54 49 30 4d 54 51 77 4d 6d 46 6a 4e 6a 42 69 59 54 4d 33 4e 32 4d 30 4d 54 55 35";

// Target folder and file path
const folderPath = path.join(__dirname, "data");
const filePath = path.join(folderPath, "leakedKeys.json");

// Ensure the folder exists
fs.mkdirSync(folderPath, { recursive: true });

// Clean and decode
const cleanHex1 = hex1.replace(/\s+/g, "");
const cleanHex2 = hex2.replace(/\s+/g, "");

const ascii1 = Buffer.from(cleanHex1, "hex").toString("utf8");
const ascii2 = Buffer.from(cleanHex2, "hex").toString("utf8");

const firstPrivateKey = Buffer.from(ascii1, "base64").toString("utf8");
const secondPrivateKey = Buffer.from(ascii2, "base64").toString("utf8");

// JSON structure
const jsonData = {
  privateKeys: [firstPrivateKey, secondPrivateKey],
};

// Write to JSON file in the specified folder
fs.writeFileSync(filePath, JSON.stringify(jsonData, null, 2));

console.log(`✅ Private keys saved to ${filePath}`);
