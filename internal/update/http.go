package update

import (
	"context"
	"fmt"
	"io"
	"net/http"
)

func get(ctx context.Context, client *http.Client, url string) (*http.Response, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	request.Header.Set("User-Agent", "dotfiles-self-update")
	response, err := client.Do(request)
	if err != nil {
		return nil, fmt.Errorf("download %s: %w", url, err)
	}
	if response.StatusCode != http.StatusOK {
		response.Body.Close()
		return nil, fmt.Errorf("download %s: HTTP %s (release must be published and publicly accessible)", url, response.Status)
	}
	return response, nil
}

func download(ctx context.Context, client *http.Client, url string, limit int64) ([]byte, error) {
	response, err := get(ctx, client, url)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	data, err := io.ReadAll(io.LimitReader(response.Body, limit+1))
	if err != nil {
		return nil, err
	}
	if int64(len(data)) > limit {
		return nil, fmt.Errorf("download %s exceeds size limit", url)
	}
	return data, nil
}
