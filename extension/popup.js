console.log('popup. js loaded');

var game = document.getElementById('game');

window.addEventListener('message', function(event) {
    var data = event.data;
    
    if (! data || !data.type) {
        return;
    }

    console.log('Popup received:', data.type);

    if (data.type === 'AI_REQUEST') {
        console.log('AI request to:', data.url);
        
        chrome.runtime.sendMessage({
            action: 'proxyFetch',
            url: data.url,
            method: data.method || 'POST',
            headers: {
                'Authorization': 'Bearer ' + data.apiKey,
                'Content-Type': 'application/json'
            },
            body: data.body
        }, function(response) {
            console.log('Background response:', response);
            
            var content = "";
            if (response && response.success && response.data) {
                var respData = response.data;
                if (respData.choices && respData.choices.length > 0) {
                    var choice = respData. choices[0];
                    if (choice.message && choice. message.content) {
                        content = choice.message.content;
                    }
                }
            }
            
            console.log('Sending AI_RESPONSE:', content);
            game.contentWindow.postMessage({
                type: 'AI_RESPONSE',
                content:  content
            }, '*');
        });
    }

    if (data. type === 'OPEN_URL') {
        console.log('Opening URL:', data.url);
        chrome.tabs.create({ url: data. url });
    }
});