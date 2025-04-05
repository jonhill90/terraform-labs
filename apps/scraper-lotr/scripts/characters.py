import os
import json
import requests
from bs4 import BeautifulSoup, NavigableString
from azure.storage.blob import BlobServiceClient
import re
import cloudscraper

def upload_to_blob(data, blob_name):
    connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    if not connection_string:
        raise Exception("Missing AZURE_STORAGE_CONNECTION_STRING environment variable.")
    
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client("lotr-data")
    blob_client = container_client.get_blob_client(blob_name)
    
    # Use ensure_ascii=False to output literal Unicode characters
    blob_client.upload_blob(json.dumps(data, indent=2, ensure_ascii=False), overwrite=True)
    print(f"Uploaded {blob_name} to Azure Blob Storage.")

def scrape_character(name):
    api_url = "https://tolkiengateway.net/w/api.php"
    params = {
        "action": "parse",
        "page": name,
        "prop": "text",
        "format": "json",
        "formatversion": "2",
        "origin": "*"  # Allow cross-origin requests
    }
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0 Safari/537.36",
        "Accept": "application/json"
    }
    
    # Use cloudscraper to bypass Cloudflare
    scraper = cloudscraper.create_scraper()
    response = scraper.get(api_url, headers=headers, params=params)
    
    try:
        data_json = response.json()
    except Exception as e:
        print("Failed to decode JSON:", e)
        print("Response text:", response.text)
        return {}
    
    html = data_json.get("parse", {}).get("text", "")
    print("DEBUG: API response HTML length:", len(html))
    
    soup = BeautifulSoup(html, 'lxml')
    data = {"name": name, "source": f"https://tolkiengateway.net/wiki/{name}"}
    
    # Loop through all table rows with tg-infobox-label and tg-infobox-data
    for row in soup.find_all("tr"):
        th = row.find("th", class_="tg-infobox-label")
        td = row.find("td", class_="tg-infobox-data")
        if th and td:
            key = th.get_text(strip=True).replace(" ", "_").replace("’", "").lower()
            values = [text for text in td.stripped_strings if not text.startswith("[")]
            data[key] = values if len(values) > 1 else values[0] if values else ""
    
    return data

def clean_character_data(data):
    cleaned = {}

    comma_fields = {
        "titles",
        "position",
        "location",
        "language",
        "birth",
        "rule",
        "death",
        "notable_for",
        "house",
        "parentage",
        "children",
        "clothing",
        "steed"
    }

    for key, value in data.items():
        if isinstance(value, list):
            # Filter out empty and junk entries
            filtered = [v.strip(", ").strip() for v in value if v.strip() and v.lower() not in ['see below', 'and']]
            # Join intelligently based on field
            if key in comma_fields:
                joined = ', '.join(filtered)
            else:
                joined = ' '.join(filtered)

            # Additional cleanup
            joined = re.sub(r"\s*'\s*", "'", joined)
            joined = re.sub(r'\s+', ' ', joined).strip()
            # If double-encoded patterns (like "Ã") appear, decode using latin1 to utf-8.
            if "Ã" in joined:
                joined = joined.encode("latin1", errors="replace").decode("utf-8", errors="replace")
            cleaned[key] = joined
        else:
            cleaned[key] = value.strip() if isinstance(value, str) else value

    return cleaned

if __name__ == "__main__":
    character_names = [
        "Aragorn", "Frodo_Baggins", "Samwise_Gamgee", "Gandalf", "Legolas",
        "Gimli", "Boromir", "Elrond", "Galadriel", "Arwen", "Bilbo_Baggins",
        "Sauron", "Saruman", "Gollum", "Théoden", "Éowyn", "Éomer",
        "Denethor_II", "Faramir", "Treebeard", "Radagast", "Glorfindel",
        "Shelob", "Lurtz", "Gríma", "Isildur", "Anárion", "Círdan",
        "Celebrimbor", "Thranduil", "Bard", "Smaug", "Balin", "Dáin_II",
        "Bifur", "Bofur", "Bombur", "Dori", "Dwalin", "Fíli", "Kíli",
        "Nori", "Óin", "Ori", "Tom_Bombadil", "Goldberry", "Rosie_Cotton",
        "Halbarad", "Gothmog"
    ]

    for character_name in character_names:
        print(f"Processing {character_name}...")
        character_data = scrape_character(character_name)
        cleaned_data = clean_character_data(character_data)
        upload_to_blob(cleaned_data, f"characters/{character_name.replace(' ', '_')}.json")