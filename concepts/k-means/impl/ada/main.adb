--  k-means clustering (Lloyd's algorithm), using only Ada's standard
--  library.
--
--  Starts from the first K points as centroids, then alternates two steps
--  until no point changes cluster: assign each point to its nearest
--  centroid, and move each centroid to the mean of its points. Ada has no
--  k-means routine, so there is no built-in to avoid.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Containers.Vectors;

procedure Main is
   K              : constant := 3;
   Max_Iterations : constant := 100;

   --  A record is a value: assigning one copies both fields.
   type Point is record
      X, Y : Long_Float;
   end record;

   package Point_Vectors is new Ada.Containers.Vectors (Positive, Point);

   subtype Cluster is Positive range 1 .. K;
   type Point_Array is array (Positive range <>) of Point;
   type Centroid_Array is array (Cluster) of Point;
   type Assignment_Array is array (Positive range <>) of Natural;

   --  The text of field number Col (counting from 1) in a CSV line.
   function Field (Line : String; Col : Positive) return String is
      Start : Positive := Line'First;
   begin
      for I in 1 .. Col - 1 loop
         Start := Index (Line (Start .. Line'Last), ",") + 1;
      end loop;
      declare
         Stop : constant Natural := Index (Line (Start .. Line'Last), ",");
      begin
         return (if Stop = 0 then Line (Start .. Line'Last)
                 else Line (Start .. Stop - 1));
      end;
   end Field;

   function Read_Points (Path : String) return Point_Array is
      File         : File_Type;
      Points       : Point_Vectors.Vector;
      X_Col, Y_Col : Natural := 0;
   begin
      Open (File, In_File, Path);
      declare
         Header : constant String := Get_Line (File);
      begin
         for C in 1 .. Ada.Strings.Fixed.Count (Header, ",") + 1 loop
            if Field (Header, C) = "x" then
               X_Col := C;
            elsif Field (Header, C) = "y" then
               Y_Col := C;
            end if;
         end loop;
      end;
      if X_Col = 0 or else Y_Col = 0 then
         raise Constraint_Error with "no x or y column";
      end if;
      while not End_Of_File (File) loop
         declare
            Line : constant String := Get_Line (File);
         begin
            if Line /= "" then
               --  Point'(...) names the aggregate's type; a bare one could
               --  also be a vector, which makes Append ambiguous.
               Points.Append (Point'(X => Long_Float'Value (Field (Line, X_Col)),
                                     Y => Long_Float'Value (Field (Line, Y_Col))));
            end if;
         end;
      end loop;
      Close (File);
      return Result : Point_Array (1 .. Natural (Points.Length)) do
         for I in Result'Range loop
            Result (I) := Points (I);
         end loop;
      end return;
   end Read_Points;

   --  Squared Euclidean distance. It ranks centroids in the same order as
   --  the distance itself, so the nearest one needs no Sqrt.
   function Squared_Distance (A, B : Point) return Long_Float is
     ((A.X - B.X) ** 2 + (A.Y - B.Y) ** 2);

   --  The closest centroid. Only a strictly smaller distance replaces the
   --  best so far, so a tie goes to the lower number.
   function Nearest (P : Point; Centroids : Centroid_Array) return Cluster is
      Best : Cluster := 1;
   begin
      for J in 2 .. K loop
         if Squared_Distance (P, Centroids (J))
            < Squared_Distance (P, Centroids (Best))
         then
            Best := J;
         end if;
      end loop;
      return Best;
   end Nearest;

   procedure Say (Name : String; Value : Long_Float) is
   begin
      Put (Name & " ");
      Put (Value, Fore => 1, Aft => 6, Exp => 0);   --  six decimals, no E
      New_Line;
   end Say;

   Points     : constant Point_Array := Read_Points (Ada.Command_Line.Argument (1));
   N          : constant Natural := Points'Length;
   Centroids  : Centroid_Array;
   --  0 means "no cluster yet", so the first pass always counts as a change.
   Assignment : Assignment_Array (1 .. N) := [others => 0];
   Iterations : Natural := 0;
   Inertia    : Long_Float := 0.0;
   Sizes      : array (Cluster) of Natural;
begin
   if N < K then
      raise Constraint_Error with "need at least 3 points";
   end if;

   for J in Cluster loop
      Centroids (J) := Points (J);   --  a copy, so moving it leaves the point
   end loop;

   while Iterations < Max_Iterations loop
      Iterations := Iterations + 1;
      declare
         New_Assignment : Assignment_Array (1 .. N);
         Sums : array (Cluster) of Point := [others => (0.0, 0.0)];
      begin
         for I in Points'Range loop
            New_Assignment (I) := Nearest (Points (I), Centroids);
         end loop;
         --  "=" on two arrays compares every element.
         exit when New_Assignment = Assignment;
         Assignment := New_Assignment;

         --  Sum each cluster's points in one pass, then divide by its size.
         Sizes := [others => 0];
         for I in Points'Range loop
            Sums (Assignment (I)).X := Sums (Assignment (I)).X + Points (I).X;
            Sums (Assignment (I)).Y := Sums (Assignment (I)).Y + Points (I).Y;
            Sizes (Assignment (I)) := Sizes (Assignment (I)) + 1;
         end loop;
         for J in Cluster loop
            if Sizes (J) > 0 then   --  an empty cluster keeps its old centroid
               Centroids (J) := (Sums (J).X / Long_Float (Sizes (J)),
                                 Sums (J).Y / Long_Float (Sizes (J)));
            end if;
         end loop;
      end;
   end loop;

   Sizes := [others => 0];
   for I in Points'Range loop
      Sizes (Assignment (I)) := Sizes (Assignment (I)) + 1;
      Inertia := Inertia + Squared_Distance (Points (I), Centroids (Assignment (I)));
   end loop;

   --  'Image puts a space before a non-negative number; Trim removes it.
   Put_Line ("iterations" & Natural'Image (Iterations));
   for J in Cluster loop
      declare
         Num : constant String := Trim (Cluster'Image (J), Ada.Strings.Left);
      begin
         Say ("centroid_" & Num & "_x", Centroids (J).X);
         Say ("centroid_" & Num & "_y", Centroids (J).Y);
      end;
   end loop;
   for J in Cluster loop
      Put_Line ("size_" & Trim (Cluster'Image (J), Ada.Strings.Left)
                & Natural'Image (Sizes (J)));
   end loop;
   Say ("inertia", Inertia);
end Main;
