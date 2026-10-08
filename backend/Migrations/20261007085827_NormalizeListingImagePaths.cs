using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class NormalizeListingImagePaths : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Photo links were saved with the emulator's address (http://10.0.2.2:5252/uploads/...),
            // which only works inside the Android emulator. Keep just the path; each
            // client adds its own server address. Photo order is preserved.
            migrationBuilder.Sql(@"
                UPDATE ""MaterialListings""
                SET ""ImageUrl"" = regexp_replace(""ImageUrl"", '^https?://(10\.0\.2\.2|localhost|127\.0\.0\.1)(:[0-9]+)?(?=/uploads/)', '')
                WHERE ""ImageUrl"" ~ '^https?://(10\.0\.2\.2|localhost|127\.0\.0\.1)(:[0-9]+)?(?=/uploads/)';

                UPDATE ""MaterialListings""
                SET ""ImageUrls"" = ARRAY(
                    SELECT regexp_replace(u, '^https?://(10\.0\.2\.2|localhost|127\.0\.0\.1)(:[0-9]+)?(?=/uploads/)', '')
                    FROM unnest(""ImageUrls"") WITH ORDINALITY AS t(u, n)
                    ORDER BY n)
                WHERE EXISTS (SELECT 1 FROM unnest(""ImageUrls"") u WHERE u ~ '^https?://(10\.0\.2\.2|localhost|127\.0\.0\.1)(:[0-9]+)?(?=/uploads/)');");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
