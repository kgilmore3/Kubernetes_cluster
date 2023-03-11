import csv
import requests

# Define the API endpoint URL
url = "https://example.com/api/universities"

# Read the data from the CSV file
universities = []
with open("universities.csv") as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        universities.append(row)

# Iterate over the universities and make a POST request to add new records or a PATCH request to update existing records
for university in universities:
    # Check if the university already exists by querying the API endpoint
    query_url = f"{url}?name={university['name']}"
    response = requests.get(query_url)
    if response.status_code == 200 and response.json():
        # The university exists, so update it with a PATCH request
        existing_university = response.json()[0]
        existing_university["country"] = university["country"]
        existing_university["website"] = university["website"]
        response = requests.patch(f"{url}/{existing_university['id']}", json=existing_university)
        print(f"Updated university: {existing_university['name']}")
    else:
        # The university doesn't exist, so add it with a POST request
        response = requests.post(url, json=university)
        print(f"Added university: {university['name']}")
        
        
        
# import requests
# import csv
# # Set the API endpoint URL
# url = 'http://universities.hipolabs.com/search?country=Canada'
# # Send a GET request to the API endpoint and store the JSON response
# response = requests.get(url)
# data = response.json()
# # Extract the necessary data from the JSON response
# universities = []
# for item in data:
#     university = {}
#     university['name'] = item['name']
#     university['country'] = item['country']
#     university['website'] = item['web_pages'][0] if len(item['web_pages']) > 0 else ''
#     universities.append(university)

# #Write the data to a CSV file
# with open('canadian_universities.csv', 'w', newline='') as csvfile:
#     fieldnames = ['name', 'country', 'website']
#     writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
#     writer.writeheader()
#     for university in universities:
#         writer.writerow(university)


#using the requests library to send a GET request to the API endpoint and retrieve the JSON response
#processes the JSON response to extract the necessary data (name, country, and website) and stores in a list of dictionaries
# uses the csv module to write the data to a CSV file, ensuring that each row represents a record and each column represents a field from the JSON response


#To run script:
#run it from the command line using python task-2.py
#make sure that the requests library is installed (you can installed using pip install requests)
