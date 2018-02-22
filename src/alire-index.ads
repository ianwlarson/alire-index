private with Alire_Early_Elaboration; pragma Unreferenced (Alire_Early_Elaboration);

with Alire.Containers;
with Alire.Compilers;
with Alire.Dependencies.Vectors;
with Alire.Operating_Systems;
with Alire.Origins;
with Alire.Properties;
with Alire.Properties.Labeled;
with Alire.Releases;
with Alire.Requisites;
with Alire.Requisites.Platform;
with Alire.Root_Project;

with Semantic_Versioning;

package Alire.Index is

   Releases : Containers.Release_Set;

   subtype Dependencies is Alire.Dependencies.Vectors.Vector;
   
   No_Dependencies : constant Dependencies      := Alire.Dependencies.Vectors.No_Dependencies;
   No_Properties   : constant Properties.Vector := Properties.No_Properties;
   No_Requisites   : constant Requisites.Tree   := Requisites.Trees.Empty_Tree;

   subtype Release      is Alire.Releases.Release;

   function Register (--  Mandatory
                      Project      : Project_Name;
                      Version      : Semantic_Versioning.Version;                      
                      Description  : Project_Description;
                      Origin       : Origins.Origin;
                      --  Optional
                      Depends_On     : Dependencies            := No_Dependencies;
                      Properties     : Alire.Properties.Vector := No_Properties;
                      Requisites     : Alire.Requisites.Tree   := No_Requisites;
                      Available_When : Alire.Requisites.Tree   := No_Requisites;
                      Native         : Boolean                 := False) return Release;
   --  Properties are of the Release; currently not used but could support License or other attributes.
   --  Requisites are properties that dependencies have to fulfill, again not used yet.
   --  Available_On are properties the platform has to fulfill; these are checked on registration.

   --  Shortcuts for common origins:
   function Git (URL : Alire.URL; Commit : Origins.Git_Commit) return Origins.Origin renames Origins.New_Git;
   function Hg  (URL : Alire.URL; Commit : Origins.Hg_Commit) return Origins.Origin renames Origins.New_Hg;

   -- Shortcuts to give dependencies:

   function V (Semantic_Version : String) return Semantic_Versioning.Version
                  renames Semantic_Versioning.New_Version;

   function Current (R : Release) return Dependencies;  
   --  Within the major of R,
   --    it will accept the newest/oldest version according to the resolution policy (by default, newest)
   --  Note: it might be older than R itself
   
   function Within_Major (R : Release) return Dependencies;
   function Within_Minor (R : Release) return Dependencies;   

   function At_Least  (R : Release) return Dependencies;
   function At_Most   (R : Release) return Dependencies;
   function Less_Than (R : Release) return Dependencies;
   function More_Than (R : Release) return Dependencies;
   function Exactly   (R : Release) return Dependencies;
   function Except    (R : Release) return Dependencies;

   subtype Version     is Semantic_Versioning.Version;
   subtype Version_Set is Semantic_Versioning.Version_Set;

   function Current (P : Project_Name) return Dependencies;  
   --  Will accept the newest/oldest version according to the resolution policy (by default, newest)
   
   function Within_Major (P : Project_Name; V : Version) return Dependencies;
   function Within_Minor (P : Project_Name; V : Version) return Dependencies;

   function At_Least  (P : Project_Name; V : Version) return Dependencies;
   function At_Most   (P : Project_Name; V : Version) return Dependencies;
   function Less_Than (P : Project_Name; V : Version) return Dependencies;
   function More_Than (P : Project_Name; V : Version) return Dependencies;
   function Exactly   (P : Project_Name; V : Version) return Dependencies;
   function Except    (P : Project_Name; V : Version) return Dependencies;

   --  Shortcuts for properties/requisites:
   
   --  "Typed" attributes (named pairs of label-value)
   function Maintainer is new Properties.Labeled.Generic_New_Label (Properties.Labeled.Maintainer);
   function Website    is new Properties.Labeled.Generic_New_Label (Properties.Labeled.Website);
   
   use all type Alire.Dependencies.Vectors.Vector;
   use all type Compilers.Compilers;
   use all type Operating_Systems.Operating_Systems;
   use all type Properties.Property'Class; 
   use all type Requisites.Requisite'Class;
   use all type Requisites.Tree;           
   --  These "use all" are useful for alire-index-* packages, but not for project_alr metadata files

   Default_Properties : constant Properties.Vector := No_Properties;
   
   function "and" (Dep1, Dep2 : Dependencies) return Dependencies renames Alire.Dependencies.Vectors."and";

   function Verifies (P : Properties.Property'Class) return Properties.Vector;
   function "+"      (P : Properties.Property'Class) return Properties.Vector renames Verifies;

   function Requires (R : Requisites.Requisite'Class) return Requisites.Tree;
   function "+"      (R : Requisites.Requisite'Class) return Requisites.Tree renames Requires;

   --  Specific shortcuts:

   function Compiler_Is_At_Least (V : Compilers.Compilers) return Requisites.Requisite'Class
                       renames Requisites.Platform.Compiler_Is_At_Least;

   function System_is (V : Operating_Systems.Operating_Systems) return Requisites.Requisite'Class
                       renames Requisites.Platform.System_Is;

   ----------------------
   -- Set_Root_Project --
   ----------------------

   function Set_Root_Project (Project    : Alire.Project_Name;
                              Version    : Semantic_Versioning.Version;
                              Depends_On : Alire.Index.Dependencies := Alire.Index.No_Dependencies)
                              return Release renames Root_Project.Set;
   --  This function must be called in the working project alire file.
   --  Otherwise alr does not know what's the current project, and its version and dependencies
   --  The returned Release is the same; this is just a trick to be able to use it in an spec file.
   
private   
   
   use Semantic_Versioning;  

   function Current (R : Release) return Dependencies is
      (New_Dependency (R.Project, Within_Major (New_Version (Major (R.Version)))));
   
   function Within_Major (R : Release) return Dependencies is
     (New_Dependency (R.Project, Within_Major (R.Version)));
   
   function Within_Minor (R : Release) return Dependencies is 
     (New_Dependency (R.Project, Within_Minor (R.Version)));

   function At_Least  (R : Release) return Dependencies is
     (New_Dependency (R.Project, At_Least (R.Version)));

   function At_Most   (R : Release) return Dependencies is
     (New_Dependency (R.Project, At_Most (R.Version)));

   function Less_Than (R : Release) return Dependencies is
     (New_Dependency (R.Project, Less_Than (R.Version)));

   function More_Than (R : Release) return Dependencies is
     (New_Dependency (R.Project, More_Than (R.Version)));

   function Exactly   (R : Release) return Dependencies is
     (New_Dependency (R.Project, Exactly (R.Version)));

   function Except    (R : Release) return Dependencies is
     (New_Dependency (R.Project, Except (R.Version)));


   function Current (P : Project_Name) return Dependencies is
      (New_Dependency (P, At_Least (V ("0.0.0"))));
   
   function Within_Major (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, Within_Major (V)));
   
   function Within_Minor (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, Within_Minor (V)));

   function At_Least  (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, At_Least (V)));

   function At_Most   (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, At_Most (V)));

   function Less_Than (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, Less_Than (V)));

   function More_Than (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, More_Than (V)));

   function Exactly   (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, Exactly (V)));

   function Except    (P : Project_Name; V : Version) return Dependencies is
     (New_Dependency (P, Except (V)));


   function Verifies (P : Properties.Property'Class) return Properties.Vector is
     (Properties.Vectors.To_Vector (P, 1));

   function Requires (R : Requisites.Requisite'Class) return Requisites.Tree is
      (Requisites.Trees.Leaf (R));

end Alire.Index;