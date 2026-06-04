# Estágio 1: Build (Mais pesado)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copia apenas o arquivo de projeto primeiro (melhora cache)
COPY ["Celticstech.csproj", "./"]
RUN dotnet restore "Celticstech.csproj"

# Copia o resto e compila
COPY . .
RUN dotnet publish "Celticstech.csproj" -c Release -o /app/publish

# Estágio 2: Runtime (Mais leve, apenas para rodar)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 8080
ENTRYPOINT ["dotnet", "Celticstech.dll"]