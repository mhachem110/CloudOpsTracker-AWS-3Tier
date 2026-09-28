using System.Net;
using System.Net.Http.Json;
using CloudOpsTracker.Web.Models;
using Microsoft.AspNetCore.Mvc;

namespace CloudOpsTracker.Web.Controllers;

public class IncidentsController : Controller
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    public IncidentsController(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    private HttpClient Api()
    {
        var baseUrl = _configuration["ApiBaseUrl"]
            ?? throw new InvalidOperationException("ApiBaseUrl is not configured.");

        var client = _httpClientFactory.CreateClient();
        client.BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/");
        return client;
    }

    public async Task<IActionResult> Index()
    {
        try
        {
            var incidents = await Api().GetFromJsonAsync<List<IncidentViewModel>>("api/incidents")
                ?? new List<IncidentViewModel>();
            return View(incidents);
        }
        catch (HttpRequestException)
        {
            ViewBag.ApiError = "The backend API is not reachable. Make sure CloudOpsTracker.API is running.";
            return View(new List<IncidentViewModel>());
        }
    }

    [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
    public IActionResult Error() => Problem("The request could not be completed. Please retry.", statusCode: 500);

    [HttpGet]
    public IActionResult Create() => View(new CreateIncidentViewModel());

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CreateIncidentViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        using var response = await Api().PostAsJsonAsync("api/incidents", model);
        if (!response.IsSuccessStatusCode)
        {
            ModelState.AddModelError("", "The API could not create the incident.");
            return View(model);
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Edit(int id)
    {
        using var response = await Api().GetAsync($"api/incidents/{id}");
        if (response.StatusCode == HttpStatusCode.NotFound) return NotFound();
        response.EnsureSuccessStatusCode();
        var incident = await response.Content.ReadFromJsonAsync<IncidentViewModel>();
        if (incident is null) return NotFound();

        return View(new EditIncidentViewModel
        {
            Id = incident.Id,
            Title = incident.Title,
            Description = incident.Description,
            Priority = incident.Priority,
            Status = incident.Status
        });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(EditIncidentViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        using var response = await Api().PutAsJsonAsync($"api/incidents/{model.Id}", model);
        if (response.StatusCode == HttpStatusCode.NotFound) return NotFound();
        if (!response.IsSuccessStatusCode)
        {
            ModelState.AddModelError("", "The API could not update the incident.");
            return View(model);
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Delete(int id)
    {
        using var response = await Api().GetAsync($"api/incidents/{id}");
        if (response.StatusCode == HttpStatusCode.NotFound) return NotFound();
        response.EnsureSuccessStatusCode();
        var incident = await response.Content.ReadFromJsonAsync<IncidentViewModel>();
        return incident is null ? NotFound() : View(incident);
    }

    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        using var response = await Api().DeleteAsync($"api/incidents/{id}");
        if (response.StatusCode == HttpStatusCode.NotFound) return NotFound();
        if (!response.IsSuccessStatusCode)
            return Problem("The API could not delete the incident. Please retry.", statusCode: 502);
        return RedirectToAction(nameof(Index));
    }
}
