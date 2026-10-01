using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <summary>
    /// Intentionally empty. This migration used to create Businesses, ProductCategories,
    /// Products, Inventories and ProductImages, but 20260911045347_AddMaterialListings
    /// creates exactly the same tables and columns, so on a fresh database the chain failed
    /// with "relation \"Businesses\" already exists". It is kept (rather than deleted) so
    /// databases that already recorded it in __EFMigrationsHistory stay consistent.
    /// </summary>
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
