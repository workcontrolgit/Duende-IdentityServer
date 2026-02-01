FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG TARGETARCH
WORKDIR /src
COPY ["src/DuendeIdentityServer.Admin.Api/DuendeIdentityServer.Admin.Api.csproj", "src/DuendeIdentityServer.Admin.Api/"]
COPY ["src/DuendeIdentityServer.Admin.EntityFramework.Shared/DuendeIdentityServer.Admin.EntityFramework.Shared.csproj", "src/DuendeIdentityServer.Admin.EntityFramework.Shared/"]
COPY ["src/DuendeIdentityServer.Admin.EntityFramework.SqlServer/DuendeIdentityServer.Admin.EntityFramework.SqlServer.csproj", "src/DuendeIdentityServer.Admin.EntityFramework.SqlServer/"]
COPY ["src/DuendeIdentityServer.Shared/DuendeIdentityServer.Shared.csproj", "src/DuendeIdentityServer.Shared/"]
COPY ["src/DuendeIdentityServer.Admin.EntityFramework.PostgreSQL/DuendeIdentityServer.Admin.EntityFramework.PostgreSQL.csproj", "src/DuendeIdentityServer.Admin.EntityFramework.PostgreSQL/"]
COPY ["src/DuendeIdentityServer.Admin.EntityFramework.MySql/DuendeIdentityServer.Admin.EntityFramework.MySql.csproj", "src/DuendeIdentityServer.Admin.EntityFramework.MySql/"]
RUN dotnet restore -a $TARGETARCH "src/DuendeIdentityServer.Admin.Api/DuendeIdentityServer.Admin.Api.csproj"
COPY . .
WORKDIR "/src/src/DuendeIdentityServer.Admin.Api"
RUN dotnet build -a $TARGETARCH "DuendeIdentityServer.Admin.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -a $TARGETARCH "DuendeIdentityServer.Admin.Api.csproj" -c Release --no-restore -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
ENTRYPOINT ["dotnet", "DuendeIdentityServer.Admin.Api.dll"]