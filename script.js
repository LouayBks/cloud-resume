document.addEventListener("DOMContentLoaded", function() {
    fetch("https://your-api-gateway-url.com/visitor-count")
        .then(response => response.json())
        .then(data => {
            document.getElementById("visitor-count").innerText = data.count;
        })
        .catch(error => console.error("Error fetching visitor count:", error));
});
