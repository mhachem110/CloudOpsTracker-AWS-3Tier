using CloudOpsTracker.API.Models;
using Microsoft.EntityFrameworkCore;

namespace CloudOpsTracker.API.Data;

public class CloudOpsDbContext : DbContext
{
    public CloudOpsDbContext(DbContextOptions<CloudOpsDbContext> options)
        : base(options)
    {
    }

    public DbSet<Incident> Incidents => Set<Incident>();
}
