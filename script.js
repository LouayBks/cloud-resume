fetch('https://4js2bfq84j.execute-api.eu-west-3.amazonaws.com/production/visitor')
  .then(response => response.json())
  .then(data => {
    console.log(data);  
    document.getElementById("visitorCount").innerText = "Visitor Count: " + data.count;  // Use data.count here
  })
  .catch(error => console.error('Error fetching visitor count:', error));
