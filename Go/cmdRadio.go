package main

import (
    "fmt"
    "net/http"
    "io/ioutil"
    "encoding/json"
    "os"
    "os/exec"
    "log"
)

type RadioStation struct {
    Name string `json:"name"`
    URL  string `json:"url_resolved"`
}

func main() {
    fmt.Println("📻 Buscando emisoras disponibles...")
    apiURL := "https://de1.api.radio-browser.info/json/stations/bycountry/spain"

    resp, err := http.Get(apiURL)
    if err != nil {
        fmt.Println("❌ Error al obtener estaciones:", err)
        return
    }
    defer resp.Body.Close()

    body, err := ioutil.ReadAll(resp.Body)
    if err != nil {
        fmt.Println("❌ Error al leer respuesta:", err)
        return
    }

    var stations []RadioStation
    json.Unmarshal(body, &stations)

    if len(stations) == 0 {
        fmt.Println("❌ No se encontraron emisoras.")
        return
    }

    // Mostrar las primeras 5 emisoras disponibles
    for i, station := range stations {
        if i >= 5 { break }
        fmt.Printf("%d. %s - %s\n", i+1, station.Name, station.URL)
    }

    // Solicitar al usuario que elija una estación
    fmt.Print("\n🔹 Introduce el número de la emisora que quieres escuchar: ")
    var choice int
    fmt.Scanln(&choice)

    if choice < 1 || choice > 5 {
        fmt.Println("❌ Opción inválida. Salida del programa.")
        return
    }

    // Reproducir la emisora elegida con mpv
    streamURL := stations[choice-1].URL
    fmt.Printf("\n▶️ Reproduciendo: %s\n", stations[choice-1].Name)

    cmd := exec.Command("mpv", streamURL)
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr

    err = cmd.Run()
    if err != nil {
        log.Fatalf("❌ Error al ejecutar mpv: %v", err)
    }
}