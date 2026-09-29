using System.Net;
using System.Net.WebSockets;
using System.Text;
using System.Text.Json;

Console.Title = "ValheimAI Controller";
Console.WriteLine("ValheimAI Controller - Milestone 1 scaffold");
Console.WriteLine("Listening for the Valheim plugin on http://127.0.0.1:8765/ws/");

using var listener = new HttpListener();
listener.Prefixes.Add("http://127.0.0.1:8765/");
listener.Start();

while (true)
{
    var context = await listener.GetContextAsync();
    if (context.Request.Url?.AbsolutePath != "/ws/" || !context.Request.IsWebSocketRequest)
    {
        context.Response.StatusCode = 404;
        context.Response.Close();
        continue;
    }

    _ = Task.Run(() => HandleClientAsync(context));
}

static async Task HandleClientAsync(HttpListenerContext context)
{
    var wsContext = await context.AcceptWebSocketAsync(null);
    var ws = wsContext.WebSocket;
    Console.WriteLine("Valheim client connected.");

    var buffer = new byte[64 * 1024];
    try
    {
        while (ws.State == WebSocketState.Open)
        {
            var result = await ws.ReceiveAsync(buffer, CancellationToken.None);
            if (result.MessageType == WebSocketMessageType.Close) break;

            var text = Encoding.UTF8.GetString(buffer, 0, result.Count);
            Console.WriteLine($"STATE {text}");

            var response = JsonSerializer.Serialize(new
            {
                type = "controller_status",
                status = "online"
            });
            var bytes = Encoding.UTF8.GetBytes(response);
            await ws.SendAsync(bytes, WebSocketMessageType.Text, true, CancellationToken.None);
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Client error: {ex.Message}");
    }
    finally
    {
        if (ws.State != WebSocketState.Closed)
            await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "closing", CancellationToken.None);
        ws.Dispose();
        Console.WriteLine("Valheim client disconnected.");
    }
}
