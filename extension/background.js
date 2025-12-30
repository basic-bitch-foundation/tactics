console.log('background.js loaded');

chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    console.log('Background received:', request. action);
    
    if (request. action === 'proxyFetch') {
        console.log('Fetching:', request.url);
        
        var fetchOptions = {
            method: request.method || 'POST',
            headers:  request.headers || {'Content-Type': 'application/json'}
        };
        
        if (request.body) {
            fetchOptions.body = request. body;
        }

        fetch(request. url, fetchOptions)
            .then(function(response) {
                console.log('Fetch status:', response.status);
                return response.json();
            })
            .then(function(data) {
                console.log('Fetch success');
                sendResponse({
                    success:  true,
                    data: data
                });
            })
            .catch(function(error) {
                console.error('Fetch error:', error);
                sendResponse({
                    success: false,
                    error: error. message
                });
            });
        
        return true;
    }
    
    return false;
});