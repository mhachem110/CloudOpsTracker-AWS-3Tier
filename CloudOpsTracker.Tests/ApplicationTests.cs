extern alias api;
using System.ComponentModel.DataAnnotations;
using System.Net;
using CloudOpsTracker.API.Models;
using CloudOpsTracker.Web.Controllers;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace CloudOpsTracker.Tests;

public class ApplicationTests
{
    [Theory]
    [InlineData("Urgent", "Open")]
    [InlineData("High", "Deleted")]
    [InlineData("123456789012345678901", "Open")]
    public void InvalidIncidentFieldsAreRejected(string priority, string status)
    {
        var request = new UpdateIncidentRequest { Title = "Test", Priority = priority, Status = status };
        Assert.False(Validator.TryValidateObject(request, new ValidationContext(request), new List<ValidationResult>(), true));
    }

    [Fact]
    public async Task MissingApiIncidentReturns404()
    {
        var controller = Controller(HttpStatusCode.NotFound);
        Assert.IsType<NotFoundResult>(await controller.Edit(7));
        Assert.IsType<NotFoundResult>(await controller.Delete(7));
    }

    [Fact]
    public async Task FailedDeleteDoesNotRedirectAsSuccess()
    {
        var result = Assert.IsType<ObjectResult>(await Controller(HttpStatusCode.InternalServerError).DeleteConfirmed(7));
        Assert.Equal(502, result.StatusCode);
    }

    [Fact]
    public async Task SuccessfulDeleteRedirectsToIndex()
    {
        var result = Assert.IsType<RedirectToActionResult>(await Controller(HttpStatusCode.NoContent).DeleteConfirmed(7));
        Assert.Equal("Index", result.ActionName);
    }

    [Fact]
    public async Task ApiStartsWithoutMigratingAndLivenessDoesNotRequireDatabase()
    {
        await using var factory = new ApiFactory();
        using var client = factory.CreateClient();
        var response = await client.GetAsync("/health/live");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ReadinessFailsWithoutLeakingConnectionDetails()
    {
        await using var factory = new ApiFactory();
        using var client = factory.CreateClient();
        var response = await client.GetAsync("/health/ready");
        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("unavailable", body);
        Assert.DoesNotContain("Server", body);
        Assert.DoesNotContain("Exception", body);
    }

    private static IncidentsController Controller(HttpStatusCode status) => new(
        new ClientFactory(status), new ConfigurationBuilder().AddInMemoryCollection(
            new Dictionary<string,string?> { ["ApiBaseUrl"] = "http://api.test" }).Build());

    private sealed class ClientFactory(HttpStatusCode status) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => new(new Handler(status));
    }

    private sealed class Handler(HttpStatusCode status) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken token)
            => Task.FromResult(new HttpResponseMessage(status));
    }

    private sealed class ApiFactory : WebApplicationFactory<api::Program>
    {
        protected override void ConfigureWebHost(IWebHostBuilder builder)
        {
            builder.UseEnvironment("Development");
            builder.UseSetting("ConnectionStrings:CloudOpsTrackerDb", "Server=127.0.0.1,1;Database=Unavailable;Integrated Security=True;Connect Timeout=1");
            builder.UseSetting("UseHttpsRedirection", "false");
        }
    }
}
