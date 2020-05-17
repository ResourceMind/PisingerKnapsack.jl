using BinDeps

@BinDeps.setup

path = dirname(@__FILE__)

libbouknap = library_dependency("libbouknap", aliases = [joinpath("x86","libbouknap"), joinpath("x64","libbouknap")])
libminknap = library_dependency("libminknap", aliases = [joinpath("x86","libminknap"), joinpath("x64","libminknap")])

pisinger_webpage_uri = "http://hjemmesider.diku.dk/~pisinger"

pisinger_files_root = joinpath(path, "..", "libpisinger")
lib_pisinger_root = joinpath(path, "libpisinger")
lib_pisinger_minknap= joinpath(lib_pisinger_root, "minknap")
lib_minknap_build = joinpath(lib_pisinger_minknap, "build")
lib_pisinger_bouknap = joinpath(lib_pisinger_root, "bouknap")
lib_bouknap_build = joinpath(lib_pisinger_bouknap, "build")

if Sys.iswindows()
    println("Build for windows.")
     
    ### Files edites for windows 
    pisinger_webpage_uri = "https://raw.githubusercontent.com/guimarqu/guimarqu.github.io/master/codes/"

    bouknapfile = joinpath(lib_pisinger_bouknap, "bouknap.c")
    provides(SimpleBuild,
        (@build_steps begin
            FileDownloader("$pisinger_webpage_uri/bouknap.c", bouknapfile)
            CreateDirectory(lib_bouknap_build)
            `cmake --build $lib_bouknap_build --config Release`
            @build_steps begin
                ChangeDirectory(lib_bouknap_build)
                `ls`
                `MSBuild bouknap.vcxproj`
                `ls`
            end
        end), libbouknap, os=:Windows)

    minknapfile = joinpath(lib_pisinger_minknap, "minknap.c")
    provides(SimpleBuild,
        (@build_steps begin
            FileDownloader("$pisinger_webpage_uri/minknap.c", minknapfile)
            CreateDirectory(lib_minknap_build)
            `cmake --build $lib_minknap_build --config Release`
            @build_steps begin
                ChangeDirectory(lib_minknap_build)
                `ls`
                `MSBuild minknap.vcxproj`
                `ls`
            end
        end), libminknap, os=:Windows)
else
    println("Build not for windows.")
    provides(SimpleBuild,
        (@build_steps begin
            FileDownloader("$pisinger_webpage_uri/bouknap.c", joinpath(lib_pisinger_bouknap, "bouknap.c"))
            if Sys.isapple() # Removing deprecated headers for osx
                @build_steps begin
                    `sed -i '' '/values\.h/d' $lib_pisinger_bouknap/bouknap.c`
                    `sed -i '' '/malloc\.h/d' $lib_pisinger_bouknap/bouknap.c`
                end
            end
            CreateDirectory(lib_bouknap_build)
            @build_steps begin
                ChangeDirectory(lib_bouknap_build)
                `cmake ..`
                MakeTargets()
            end
        end), libbouknap, installed_libpath = lib_bouknap_build)

    provides(SimpleBuild,
        (@build_steps begin
            FileDownloader("$pisinger_webpage_uri/minknap.c", joinpath(lib_pisinger_minknap, "minknap.c"))
            if Sys.isapple() # Removing deprecated headers for osx
                @build_steps begin
                    `sed -i '' '/values\.h/d' $lib_pisinger_minknap/minknap.c`
                    `sed -i '' '/malloc\.h/d' $lib_pisinger_minknap/minknap.c`
                end
            end
            CreateDirectory(lib_minknap_build)
            @build_steps begin
                ChangeDirectory(lib_minknap_build)
                `cmake ..`
                MakeTargets()
            end
        end), libminknap, installed_libpath = lib_minknap_build)
end

Sys.iswindows() && push!(BinDeps.defaults, BuildProcess)

@BinDeps.install Dict(:libbouknap => :_jl_libbouknap,
                      :libminknap => :_jl_libminknap)

Sys.iswindows() && pop!(BinDeps.defaults)