import os
import json
import re
import cloudscraper
from bs4 import BeautifulSoup
from azure.storage.blob import BlobServiceClient

def upload_to_blob(data, blob_name):
    connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    if not connection_string:
        raise Exception("Missing AZURE_STORAGE_CONNECTION_STRING environment variable.")

    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    container_client = blob_service_client.get_container_client("lotr-data")
    blob_client = container_client.get_blob_client(blob_name)

    blob_client.upload_blob(json.dumps(data, indent=2, ensure_ascii=False), overwrite=True)
    print(f"Uploaded {blob_name} to Azure Blob Storage.")

def scrape_location(name):
    api_url = "https://tolkiengateway.net/w/api.php"
    params = {
        "action": "parse",
        "page": name,
        "prop": "text",
        "format": "json",
        "formatversion": "2",
        "origin": "*"
    }
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Accept": "application/json"
    }

    scraper = cloudscraper.create_scraper()
    response = scraper.get(api_url, headers=headers, params=params)

    try:
        data_json = response.json()
    except Exception as e:
        print("Failed to decode JSON:", e)
        print("Response text:", response.text)
        return {}

    html = data_json.get("parse", {}).get("text", "")
    soup = BeautifulSoup(html, 'lxml')
    data = {"name": name, "source": f"https://tolkiengateway.net/wiki/{name}"}

    for row in soup.find_all("tr"):
        th = row.find("th", class_="tg-infobox-label")
        td = row.find("td", class_="tg-infobox-data")
        if th and td:
            key = th.get_text(strip=True).replace(" ", "_").replace("’", "").lower()
            values = [text for text in td.stripped_strings if not text.startswith("[")]
            data[key] = values if len(values) > 1 else values[0] if values else ""

    return data

def clean_location_data(data):
    cleaned = {}
    comma_fields = {
        "other_names", "location", "population", "language",
        "governance", "preceded_by", "founded", "first_siege", 
        "second_siege", "council_of_elrond", "abandoned", "gallery"
    }

    for key, value in data.items():
        if isinstance(value, list):
            filtered = [v.strip(", ").strip() for v in value if v.strip()]
            joined = ', '.join(filtered) if key in comma_fields else ' '.join(filtered)
            joined = re.sub(r"\s*'\s*", "'", joined)
            joined = re.sub(r'\s+', ' ', joined).strip()
            joined = joined.encode('utf-8', errors='replace').decode('utf-8', errors='replace')
            cleaned[key] = joined
        else:
            cleaned[key] = value.strip() if isinstance(value, str) else value

    return cleaned

if __name__ == "__main__":
    locations = [
        "Rivendell",
        "Gondor",
        "Mordor",
        "Shire",
        "Rohan",
        "Arnor",
        "Eriador",
        "Lothlórien",
        "Isengard",
        "Mirkwood"
    ]

    for location_name in locations:
        print(f"Scraping {location_name}...")
        location_data = scrape_location(location_name)
        cleaned_data = clean_location_data(location_data)
        upload_to_blob(cleaned_data, f"locations/{location_name.replace(' ', '_')}.json")
