defmodule Servy.Handler do
  require Logger

  import Servy.Parser, only: [parse: 1]
  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]

  @pages_path Path.join(['..', '..', 'pages'])

  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> track
    |> format_response
  end

  def route(%{method: "GET", path: "/wildthings"} = request) do
    %{request | response_body: "Bears, Lions, Tigers", status_code: 200}
  end

  def route(%{method: "GET", path: "/bears"} = request) do
    %{request | response_body: "Teddy, Smokey, Paddington", status_code: 200}
  end

  def route(%{method: "GET", path: "/bears/" <> id} = request) do
    %{request | response_body: "Bear #{id}", status_code: 200}
  end

  def route(%{method: "DELETE", path: "/bears/" <> _id} = request) do
    %{request | response_body: "Bears must never be deleted"}
  end

  def route(%{method: "GET", path: "/pages/" <> page} = request) do
    file =
      @pages_path
      |> Path.expand(__DIR__)
      |> Path.join(page <> ".html")

    Logger.info("Serving request to page #{file}")

    # We can use multi clause function here, but for learning I won't
    case File.read(file) do
      {:ok, content} ->
        %{request | status_code: 200, response_body: content}

      {:error, :enoent} ->
        %{request | status_code: 404, response_body: "File not found!"}

      {:error, reason} ->
        %{request | status_code: 500, response_body: "File error: #{reason}"}
    end
  end

  def route(%{path: path} = request) do
    %{request | response_body: "No #{path} here", status_code: 404}
  end

  def format_response(%{response_body: response_body, status_code: status_code}) do
    """
    HTTP/1.1 #{status_reason(status_code)}
    Content-Type: text/html
    Content-Length: #{String.length(response_body)}

    #{response_body}
    """
  end

  defp status_reason(code) do
    %{
      200 => "OK",
      201 => "Created",
      401 => "Unauthorized",
      403 => "Forbidden",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end
end
